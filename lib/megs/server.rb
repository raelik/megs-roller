require 'megs/tables'
require 'megs/error'
require 'rack/utils'
require 'json'
require 'openssl'

module MEGS
  class Server
    VALID_PATHS = {
     '/action_roll' => { method: 'GET', required: %w(av ov), handler: :action_roll },
     '/effect_resolve' => { method: 'GET', required: %w(ev rv), handler: :effect_resolve }
    }.freeze

    attr_reader :request, :config, :action, :last_roll, :total, :signature
    def initialize(config)
      @config = config
      puts "ACTION TABLE:"
      Tables::ACTION_TABLE.each.with_index { |row,i| puts "%02d -> %s" % [i, row.inspect] }
    end

    def validate_request(env)
      @request = Rack::Request.new(env)
      path = VALID_PATHS[path_info]
      raise Error.new(404, "File not found: #{path_info}") unless path
      raise Error.new(405, "Method #{request.method} not allowed for #{path_info}") unless path[:method] == request.request_method
      missing = path[:required].select { |k| params[k].nil? }
      raise Error.new(400, "missing required param: #{missing.join(', ')}") unless missing.empty?
      path[:handler]
    end

    def validate_cookie
      return true if cookie['sig'].nil? && cookie['action'].nil? && cookie['last_roll'].nil? && cookie['total'].nil?
      @signature = cookie['sig']
      @action    = cookie['act'].split('&').map(&:to_i)
      @last_roll = cookie['roll'].split('&').map(&:to_i)
      @total     = cookie['tot'].to_i
      json = { act: @action, tot: @total, roll: @last_roll }.to_json
      new_sig = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), config['secret'], json)
      Rack::Utils.secure_compare(signature, new_sig)
    end

    def generate_signature
      json = { act: @action, tot: @total, roll: @last_roll }.to_json
      @signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), config['secret'], json)
    end

    def set_cookies(headers)
      generate_signature
      { act: @action, tot: @total, roll: @last_roll, sig: @signature }.each do |k,v|
        Rack::Utils.set_cookie_header!(headers, k.to_s, { value: v, max_age: 3600, expires: Time.now + 3600 })
      end
      headers
    end

    def new_action?(av, ov, ov_cs)
      action.nil? || action[0..2] != [av, ov, ov_cs]
    end

    def params
      request.params
    end

    def path_info
      request.path_info
    end

    def roll
      rolls = []
      2.times do
        rolls << ((Random.rand(1000) + 1) % 10) + 1
      end
      rolls
    end

    def action_roll
      av, ov, ov_cs = params.values_at('av','ov','ov_cs').map(&:to_i)

      new_roll = roll
      sum = new_roll.sum
      if params['reroll'] && !new_action?(av, ov, ov_cs) && last_roll[0] == last_roll[1] && last_roll.first != 1
        if sum == 2
          @total = 2
        else
          @total += sum
        end
        target = action.last
      else
        @total = new_roll.sum

        indexes = [av, ov].map { |v| Tables.get_index(v) }
        indexes[1] = (ov_cs < 0 && ov_cs.abs >= indexes[1]) ? 0 : indexes[1] + ov_cs

        if indexes[0] > Tables::MAX_INDEX
          if indexes[0] == indexes[1]
            indexes[0] = Tables::MAX_INDEX
            indexes[1] = Tables::MAX_INDEX
          else
            diff = indexes[0] - Tables::MAX_INDEX
            indexes[0] = Tables::MAX_INDEX
            indexes[1] -= diff
            indexes[1] = 0 if indexes[1] < 0
          end
        end

        target_extra = 0
        if indexes[1] > Tables::MAX_INDEX
          row_shift = indexes[1] - Tables::MAX_INDEX
          indexes[1] = Tables::MAX_INDEX
          if indexes[0] - row_shift >= 1
            indexes[0] -= row_shift
          else
            target_extra = (row_shift  - (indexes[0] - 1)) * 10
            indexes[0] = 1
          end
        end

        #ranges  = indexes.map { |i| Tables::RANGE_INDEXES[i] }
        puts "AV index: #{indexes[0]}, OV index: #{indexes[1]}"
        target = Tables::ACTION_TABLE[indexes[0]][indexes[1]] + target_extra

        @action = [av, ov, ov_cs, target]
      end
      @last_roll = new_roll

      headers = { 'content-type' => 'application/json' }
      output = { av: av, ov: av, ov_cs: ov_cs, target: target, total: @total, last_roll: @last_roll }.to_json

      [200, set_cookies(headers), [output]]
    end

    def effect_resolve
    end

    def call(env)
      handler = validate_request(env)
      self.send(handler)
    rescue Error => e
      headers = {}
      %w(sig action last_roll total).each { |k| Rack::Utils.delete_cookie_header(headers, k) } if e.status == 401
      [e.status, headers, [e.message]]
    end
  end
end
