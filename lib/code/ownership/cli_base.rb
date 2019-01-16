# frozen_string_literal: true

module Code
  module Ownership
    # CLIBase collects shared methods used by all CLI sub commands
    # It loads and validate the default config file or output an explanation
    # about how to configure it.
    class CLIBase < Thor
      def initialize(*args)
        super
        @repo_base_path = `git rev-parse --show-toplevel`.chomp
      end

      no_commands do
        def default_team_file
          @repo_base_path + '/.default_team'
        end

        def default_team
          return unless File.exist?(default_team_file)

          IO.read(default_team_file).chomp
        end

        def validate_team_file
          return true if File.exist?(default_team_file) || options[:team]

          banner_how_to_config_team
        end

        def banner_how_to_config_team
          puts 'Please provide a team name or configure a default team.',
               "Try `#{$PROGRAM_NAME} config --team <team-name>` to configure the team."
          false
        end
      end
    end
  end
end
