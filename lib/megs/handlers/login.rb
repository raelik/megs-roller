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

        def enabled
          MEGS::DB.config && (config['memcache_server']) &&
          (config['login'].nil? || config['login'])
        end

        def validate_session(request)
          cookies = request.cookies
          if id = cookies['sess']
            if (s = request.session) && s.id.to_s == id && s[:key] &&
               (signature = Base64.decode64(request.get_header('HTTP_X_MEGS_SESSION_SIGNATURE')) rescue nil)
              data = request.get_header(Rack::RACK_REQUEST_COOKIE_STRING)
              raise ArgumentError.new("verification failed") unless s[:key].verify("SHA256", signature, data)
              s.options[:skip] = false
              s
            else
              s && s.options[:drop] = true
              false
            end
          end
        rescue => e
          puts "ERROR: #{e.message}"
          e.backtrace.each { |line| puts line }
          raise Error.new(401, "Session data invalid: #{e.message}")
        end
      end

      def update_session(s)
        discord, logging = params.values_at('d', 'l').map(&:to_s)
        if discord != '' && s[:discord] != discord
          s[:discord] = (discord == 'true')
        end
        if logging != '' && s[:user][:admin] && s[:logging] != logging
          s[:logging] = (logging == 'true')
        end
      end

      attr_reader :config, :request, :headers
      def initialize(_c, req)
        @request = req
        @headers = { 'content-type' => 'application/json' }
      end

      def call
        s, h, b = case [request.request_method, request.path_info]
          when ['GET',  '/login']
            s = enabled && self.class.validate_session(request)
            Rack::Utils.delete_cookie_header!(headers, 'sess') if s == false
            update_session(s) if s && (params['d'] || params['l'])
            default = { enabled: enabled }.merge(params['d'] || params['l'] ? {} : { key: keys['public'] })
            [200, headers, (default.merge(s ? { session: get_session_data(s) } : {}).to_json)]
          when ['POST', '/login']
            data = enabled && (Hash[URI.decode_www_form(keys['private'].
                                        private_decrypt(Base64.decode64(request.POST['data'])))] rescue nil)
            user_query = data && MEGS::DB[:users].by_username(data['u']).combine(:characters)

            if data && (user = user_query.first) && user.password.is_password?(data['p']) &&
               (key = OpenSSL::PKey::RSA.new(Base64.decode64(request.get_header('HTTP_X_MEGS_SESSION_KEY'))))
              set_session(request.session, key, user)
              [200, headers, get_session_data(request.session).to_json]
            else
              raise Error.new(401, "Unauthorized")
            end
          when ['GET',  '/logout']
            s = enabled && self.class.validate_session(request)
            s && s.options[:drop] = true
            Rack::Utils.delete_cookie_header!(headers, 'sess')
            [200, headers, { logging: true, discord: true }.to_json]
          else
            [404, {}, "Not Found"]
        end
        [s, h, [b]]
      rescue Error => e
        headers = {}
        if e.status == 401
          s && s.options[:drop] = true
          Rack::Utils.delete_cookie_header!(headers, 'sess')
        end
        [e.status, headers, [e.message]]
      end

      def keys
        self.class.keys
      end

      def params
        request.params
      end

      def enabled
        self.class.enabled
      end

      private

      def users
        MEGS::DB[:users]
      end

      def set_session(s, key, user)
        s.options[:skip] = false
        cipher = OpenSSL::Cipher::AES.new(128, :CFB)
        s.merge!(key: key, user: user.to_h, current_rolls: [],
                 cipher: { key: cipher.random_key, iv: cipher.random_iv },
                 logging: true, discord: true)
        chars = (user.admin ? MEGS::DB[:characters].combine(:user).order(:user_id, :id) : user.characters).to_a
        s[:chars] =
          Hash[chars.map do |char|
            [char.id, char.to_h]
          end]
      end

      def get_session_data(s)
       { user: s[:user].filter { |k| %i(id username name admin).include?(k) },
         chars: { 0 => s[:user][:name] }.merge(Hash[s[:chars].map do |k, v|
           [ k, v[:name] + (s[:user][:admin] ? " (#{v[:user][:name]})" : '') ]
         end]), logging: s[:logging], discord: s[:discord] }
      end
    end
  end
end
