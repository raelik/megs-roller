require 'openssl'
require 'megs/handlers/login'
require 'megs/db'
require 'discordrb/webhooks'
require 'numbers_and_words'
require 'concurrent/executor/thread_pool_executor'

module MEGS
  module Handlers
    class Base
      ALLOWED_METHODS = %w(GET)
      REQUIRED_PARAMS = []

      # success, resolved and last_roll are intentionally not included here
      MEGS_KEYS = %i(user char av ov ov_cs av_index ov_index ev rv rv_cs
                     ev_index rv_index target target total cs raps).freeze

      IMG_BASE_URL = 'https://raw.githubusercontent.com/raelik/megs-roller/refs/heads/roll_log_and_character_db/public/img/'.freeze
      @discord = nil
      @pool = Concurrent::ThreadPoolExecutor.new(min_threads: 5, max_threads: 5, max_queue: 1, fallback_policy: :caller_runs)
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

        attr_reader :discord, :pool
        def setup(webhook_url)
          @discord = Discordrb::Webhooks::Client.new(url: webhook_url)
        end
      end

      attr_reader :config, :headers, :request, :megs, :session
      def initialize(conf, req)
        @config  = conf
        @request = req
        @headers = { 'content-type' => 'application/json' }
        @megs    = {}
        @session = Login.enabled && Login.validate_session(req)
        Rack::Utils.delete_cookie_header!(headers, 'sess') if session == false
        raise Error.new(401, "Cookie signature invalid") unless validate_cookie
      end

      def megs=(cookie_str)
        arr      = cookie_str.split('&')
        last     = arr.pop(2).map(&:to_i)
        resolved = arr.pop
        success  = arr.pop
        @megs = Hash[MEGS_KEYS.zip(arr.map(&:to_i))]
        @megs[:last_roll] = last
        @megs[:resolved] = true unless resolved.to_s.empty?
        @megs[:success]  = (success == 'true') unless success.to_s.empty?
        @megs
      end

      def megs_cookie
        (megs.values_at(*MEGS_KEYS) + [megs[:success].to_s, megs[:resolved].to_s] + (megs[:last_roll] || [])).join('&')
      end

      def validate_cookie
        return true if cookies['sig'].nil? && cookies['megs'].nil?
        return true if cookies['sig'].empty? && cookies['megs'].empty?
        signature = cookies['sig']
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
          session['current_rolls'].clear if session
          delete_cookies(headers)
          [200, headers, [{}.to_json]]
        else
          missing = missing_params
          raise Error.new(400, "Missing required param: #{missing.join(', ')}") unless missing.empty?
          s, h, b = self.send(request_method.downcase.to_sym)
          set_cookies(h) if megs
          [s, h, b]
        end
      rescue NoMethodError => e
        raise Error.new(405, "Method #{request_method} not allowed for #{path_info}")
      rescue Error => e
        @headers = {}
        delete_cookies(headers) if e.status == 401
        [e.status, headers, [e.message]]
      end

      def log_roll
        if session&.dig(:logging)
          timestamp = (Time.now.to_f * 10000000).to_i
          MEGS::DB[:rolls].changeset(:create, { timestamp: timestamp, session_id: session.id.to_s,
                                                user_id: megs[:user], character_id: megs[:char] == 0 ? nil : megs[:char],
                                                rolls: session[:current_rolls] }.merge(log_fields)).commit
          send_to_discord(timestamp) if session[:discord]
        end
      end

      def send_to_discord(timestamp)
        MEGS::Handlers::Base.pool.post do
          r = MEGS::DB[:rolls].by_pk(timestamp, session.id.to_s).combine(:user, :character).
                               node(:character) { |c| c.combine(:user) }.one
          success = r.success
          an_or_a = (r.total.to_words[0] == 'e' ? 'an' : 'a')

          MEGS::Handlers::Base.discord&.execute do |builder|
            builder.content = "#{r.user.name} attempted a *Dice Action*."
            builder.add_embed do |embed|
              embed.author = Discordrb::Webhooks::EmbedAuthor.new(
                name: r.character&.name || r.user.name,
                icon_url: IMG_BASE_URL + (success ? 'success' : 'failure') + '.png')
              embed.title     = "( *owned by #{r.character&.user&.name}* )" if r.character && r.user.admin && r.character.user_id != r.user.id
              embed.color     = success ? '#25ae88' : '#d75a4a'
              embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: IMG_BASE_URL + '2d10.png')
              embed.timestamp = Time.at(timestamp / 10000000.0)
              embed.description = "rolled #{an_or_a} **#{r.total}** vs. a target number of **#{r.target}**" +
                                   (success ? ", earning **#{r.cs}** *Column Shifts*.\n" : ".\n") +
                                  "[ *AV **#{r.av}** against OV **#{r.ov}**" +
                                   (r.ov_cs.to_i == 0 ? '* ]' : ", **#{r.ov_cs}** OV CS #{r.ov_cs < 0 ? 'Penalty' : 'Bonus'}* ]") +
                                  "\n  \n" + (success ? "**RAPs: #{r.raps}**\n[ *EV **#{r.ev}** against RV **#{r.rv}**" +
                                   (r.rv_cs.to_i == 0 ? '* ]' : ", **#{r.rv_cs}** RV CS #{r.rv_cs < 0 ? 'Penalty' : 'Bonus'}* ]") + "\n  \n" : '') +
                                  "**Dice Rolled: #{r.rolls.flatten.join(', ')}**"
            end
          end
        end
      end

      def log_fields
        fail NotImplementedError, "Handler classes must define log_fields."
      end

      # passthrough methods
      def generate_signature(payload)
        self.class.generate_signature(config['secret'], (session ? session.id.to_s : '') + payload)
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
