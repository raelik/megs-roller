require 'openssl'

module MEGS
  module Handlers
    class Base
      ALLOWED_METHODS = %w(GET)
      REQUIRED_PARAMS = []

      # last_roll is intentionally not included here
      MEGS_KEYS = %i(av ov ov_cs av_index ov_index
                     ev rv rv_cs ev_index rv_index
                     target total cs raps).freeze

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

      attr_reader :config, :headers, :request, :megs
      def initialize(config, request)
        @config  = config
        @request = request
        @headers = { 'content-type' => 'application/json' }
        @megs    = {}
        raise Error.new(401, "Cookie signature invalid") unless validate_cookie
      end

      def megs=(cookie_str)
        arr  = cookie_str.split('&').map(&:to_i)
        last = arr.pop(2)
        @megs = Hash[MEGS_KEYS.zip(arr)]
        @megs[:last_roll] = last
      end

      def megs_cookie
        (megs.values_at(*MEGS_KEYS) + megs[:last_roll]).join('&')
      end

      def validate_cookie
        return true if cookies['sig'].nil? && cookies['megs'].nil?
        return true if cookies['sig'].empty? && cookies['megs'].empty?
        signature = cookies['sig']
        check_sig = generate_signature(config['secret'], cookies['megs'])
        Rack::Utils.secure_compare(signature, check_sig) && (self.megs = cookies['megs'])
      end

      def set_cookies(h)
        { megs: megs_cookie, sig: generate_signature(config['secret'], megs_cookie) }.each do |k,v|
          Rack::Utils.set_cookie_header!(h, k.to_s, { value: v, max_age: 3600, expires: Time.now + 3600 })
        end
        h
      end

      def delete_cookies(h)
        %w(sig megs).each { |k| Rack::Utils.delete_cookie_header!(headers, k) }
      end

      def call
        if params['clear']
          delete_cookies(headers)
          [200, headers, [{}.to_json]]
        else
          s, h, b = serve
          set_cookies(h)
          [s, h, b]
        end
      rescue Error => e
        headers = {}
        delete_cookies(headers) if e.status == 401
        [e.status, headers, [e.message]]
      end

      # passthrough methods
      def generate_signature(secret, payload)
        Handlers::Base.generate_signature(secret, payload)
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
    end
  end
end
