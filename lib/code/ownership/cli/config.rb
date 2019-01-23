# frozen_string_literal: true

require_relative 'base'

module Code
  module Ownership
    module Cli
      class Config < Base
        default_task :list

        desc 'list', 'List the default team configured in the config file'
        def list
          puts(config.to_h.map { |name, value| "#{name}: #{value.inspect}" })
          help_stderr if config.default_team.empty?
        end

        desc 'team <name>', 'Configure a default team name'
        def team(name)
          config.default_team = name
          puts "Default team configured to #{name}"
        end
      end
    end
  end
end
