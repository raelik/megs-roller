require 'megs/db'
require 'openssl'
require 'base64'
require 'uri'
require 'json'

module MEGS
  module Handlers
    # Does not inherit from base handler.
    class Login

      @config   = {}
      @keys     = {}
      class << self
        attr_reader :config, :keys
        def setup(conf)
          raise ArgumentError.new("Required configuration parameter 'keys' undefined") unless conf['keys']
          raise ArgumentError.new("Required 'keys' subparameter 'public' undefined")   unless conf['keys']['public']
          raise ArgumentError.new("Required 'keys' subparameter 'private' undefined")  unless conf['keys']['private']
          @config = conf
          @keys   = conf['keys'].reduce({}) do |hash, (k, v)|
            hash[k] = (k == 'private') ? OpenSSL::PKey::RSA.new(File.read(v)) : File.read(v)
            hash
          end
        end

        def validate_session(request)
          cookies = request.cookies
          if id = cookies['sess']
            if (s = request.session) && s.id.to_s == id
              signature = Base64.decode64(request.get_header('HTTP_X_MEGS_SESSION_SIGNATURE'))
              data = %w(sess megs sig).filter { |k| !cookies[k].nil? }.map { |k| "#{k}=#{URI.encode_www_form_component(cookies[k])}" }.join('; ')
              raise ArgumentError.new("verification failed") unless s[:key].verify("SHA256", signature, data)
              s
            else
              false
            end
          end
        rescue => e
          puts "ERROR: #{e.message}"
          e.backtrace.each { |line| puts line }
          raise Error.new(401, "Session data invalid: #{e.message}")
        end
      end

      attr_reader :config, :request, :headers
      def initialize(_c, req)
        @request = req
        @headers = { 'content-type' => 'appliction/json' }
      end

      def call
        s, h, b = case [request.request_method, request.path_info]
          when ['GET',  '/login']
            session = self.class.validate_session(request)
            Rack::Utils.delete_cookie_header!(headers, 'sess') if session == false
            [200, headers, { key: keys['public'] }.to_json]
          when ['POST', '/login']
            data = Hash[URI.decode_www_form(keys['private'].private_decrypt(Base64.decode64(request.POST['data'])))]
            user_query = MEGS::DB[:users].by_username(data['u'])

            if (user = user_query.first) && user[:password].is_password?(data['p']) &&
               (key = OpenSSL::PKey::RSA.new(Base64.decode64(request.get_header('HTTP_X_MEGS_SESSION_KEY'))))
              set_session(request.session, key, user)
              [200, headers, get_session_data(request.session)]
            else
              raise Error.new(401, "Unauthorized")
            end
          when ['GET',  '/logout']
            self.class.validate_session(request)
            s && s.options[:drop] = true
            Rack::Utils.delete_cookie_header!(headers, 'sess')
            [204, headers, []]
          else
            [404, {}, "Not Found"]
        end
        [s, h, [b]]
      rescue Error => e
        headers = {}
        [e.status, headers, [e.message]]
      end

      def keys
        self.class.keys
      end

      private

      def users
        MEGS::DB[:users]
      end

      def set_session(s, key, user)
        s.options[:skip] = false
        s.merge!(key: key, user: user)
        s[:chars] =
          Hash[(user[:admin] ? MEGS::DB[:characters] : user.characters).map do |char|
            [char[:id], char]
          end]
      end

      def get_session_data(s)
       { user: s[:user].filter { |k| %i(id username name admin).include?(k) },
         chars: { 0 => s[:user][:name] }.merge(Hash[s[:chars].map { |k, v| [ k, v[:name] ] }]) }.to_json
      end
    end
  end
end
