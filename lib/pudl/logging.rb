require 'logger'

module Pudl

  # Global logging module
  #
  module Logging

    class FakeLogger < ::Logger
      def initialize(*args)
      end
      def add(*args, &block)
      end
    end

    @@mutex = Mutex.new
    @@logger = nil

    # Get the current shared logger instance
    # in a class context
    #
    def self.logger
      @@mutex.synchronize do
        if @@logger
          @@logger
        else
          @@logger = FakeLogger.new
        end
      end
    end

    # Set a custom logger object to be shared
    #
    def self.logger= l
      @@logger = l
    end

    # Get the current shared logger instance
    # in an instance context
    #
    def logger
      Logging.logger
    end

  end

end
