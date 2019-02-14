# frozen_string_literal: true

require_relative 'base'

module Codeowners
  module Cli
    # Provide options for configuring the default owner used for filtering changes.
    class Config < Base
      default_task :list

      desc 'list', 'List the default owner configured in the config file'
      def list
        puts(config.to_h.map { |name, value| "#{name}: #{value.inspect}" })
        help_stderr if config.default_owner.empty?
      end

      desc 'owner <name>', 'Configure a default owner name'
      def owner(name)
        config.default_owner = name
        puts "Default owner configured to #{name}"
      end
    end
  end
end
