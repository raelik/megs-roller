require 'openssl'
require 'megs/handlers/login'

module MEGS
  module Handlers
    class Base
      ALLOWED_METHODS = %w(GET)
      REQUIRED_PARAMS = []

      # success, resolved and last_roll are intentionally not included here
      MEGS_KEYS = %i(user char av ov ov_cs av_index ov_index ev rv rv_cs
                     ev_index rv_index target target total cs raps).freeze

      class << self
        def generate_signature(secret, payload)
          OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, payload)
        end

        def method_allowed?(method)
          self::ALLOWED_METHODS.include?(method)
        end

        def missing_params(params)
          params['clear'] ? [] : self::REQUIRED_PARAMS.select { |k| params[k].nil? }
        end
      end

      attr_reader :config, :headers, :request, :megs, :session
      def initialize(conf, req)
        @config  = conf
        @request = req
        @headers = { 'content-type' => 'application/json' }
        @megs    = {}
        @session = Login.validate_session(req)
        raise Error.new(401, "Cookie signature invalid") unless validate_cookie
      end

      def megs=(cookie_str)
        arr      = cookie_str.split('&')
        last     = arr.pop(2).map(&:to_i)
        resolved = arr.pop
        success  = arr.pop
        @megs = Hash[MEGS_KEYS.zip(arr.map(&:to_i))]
        @megs[:last_roll] = last
        @megs[:resolved] = true unless resolved.empty?
        @megs[:success]  = (success == 'true') unless success.empty?
      end

      def megs_cookie
        (megs.values_at(*MEGS_KEYS) + [megs[:success].to_s, megs[:resolved].to_s] + megs[:last_roll]).join('&')
      end

      def validate_cookie
        return true if cookies['sig'].nil? && cookies['megs'].nil?
        return true if cookies['sig'].empty? && cookies['megs'].empty?
        signature  = cookies['sig']
        check_sig = generate_signature(cookies['megs'])
        Rack::Utils.secure_compare(signature, check_sig) && (self.megs = cookies['megs'])
      end

      def set_cookies(h)
        { megs: megs_cookie, sig: generate_signature(megs_cookie) }.each do |k,v|
          Rack::Utils.set_cookie_header!(h, k.to_s, { value: v, max_age: 3600, expires: Time.now + 3600 })
        end
        h
      end

      def delete_cookies(h)
        %w(sig megs).each { |k| Rack::Utils.delete_cookie_header!(h, k) }
      end

      def call
        if params['clear']
          delete_cookies(headers)
          [200, headers, [{}.to_json]]
        else
          missing = missing_params
          raise Error.new(400, "Missing required param: #{missing.join(', ')}") unless missing.empty?
          s, h, b = self.send(request_method.downcase.to_sym)
          set_cookies(h)
          [s, h, b]
        end
      rescue NoMethodError => e
        raise Error.new(405, "Method #{request_method} not allowed for #{path_info}")
      rescue Error => e
        @headers = {}
        delete_cookies(headers) if e.status == 401
        [e.status, headers, [e.message]]
      end

      # passthrough methods
      def generate_signature(payload)
        self.class.generate_signature(config['secret'], payload)
      end

      def missing_params
        self.class.missing_params(params)
      end

      def params
        request.params
      end

      def path_info
        request.path_info
      end

      def cookies
        request.cookies
      end

      def request_method
        request.request_method
      end
    end
  end
end
