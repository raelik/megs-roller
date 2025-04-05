require 'megs/db'
require 'openssl'
require 'base64'
require 'uri'
require 'json'
require 'securerandom'
require 'concurrent/hash'

module MEGS
  module Handlers
    # Does not inherit from base handler.
    class Login

      @config   = {}
      @keys     = {}
      @sessions = Concurrent::Hash.new
      class << self
        attr_reader :config, :keys, :sessions
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
            if s = sessions[id]
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
        @headers = { 'allow' => 'GET, POST', 'content-type' => 'appliction/json' }
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
              (id = SecureRandom.uuid) until id && sessions[id].nil?
              set_session(id, key, user)
              Rack::Utils.set_cookie_header!(headers, 'sess', { value: id, max_age: 3600, expires: Time.now + 3600 })
              [200, headers, get_session_data(id)]
            else
              raise Error.new(401, "Unauthorized")
            end
          when ['GET',  '/logout']
            self.class.validate_session(request)
            sessions.delete(request.cookies['sess'])
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

      def sessions
        self.class.sessions
      end

      private

      def users
        MEGS::DB[:users]
      end

      def set_session(id, key, user)
        sessions[id] = { key: key, user: user }
        sessions[id][:chars] = (user[:admin] ? MEGS::DB[:characters] : user.characters).to_a
      end

      def get_session_data(id)
       s = sessions[id]
       { user: s[:user].filter { |k| %i(id username name admin).include?(k) },
         chars: s[:chars].map { |c| { id: c[:id], name: c[:name] } } }.to_json
      end
    end
  end
end
