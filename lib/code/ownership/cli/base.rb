# frozen_string_literal: true

require 'thor'
require_relative '../config'

module Code
  module Ownership
    module Cli
      # Base collects shared methods used by all CLI sub commands
      # It loads and validate the default config file or output an explanation
      # about how to configure it.
      class Base < Thor
        def initialize(args = [], options = {}, config = {})
          super
          @config ||= config[:config] || default_config
        end

        private

        attr_reader :config

        def default_config
          Code::Ownership::Config.new
        end

        def help_stderr
          save_stdout = $stdout
          $stdout = $stderr
          help
          $stdout = save_stdout
        end
      end
    end
  end
end
