require 'rom'
require 'rom-sql'

module MEGS
  module DB
    class << self
      attr_reader :config, :rom_config, :rom

      def configure(database)
        @config = database
      end

      def connect
        @rom_config = ROM::Configuration.new(:sql, config)
        rom_config.auto_registration(File.dirname(__FILE__), namespace: 'MEGS')
        @rom = ROM.container(rom_config)
      end
    end
  end
end
