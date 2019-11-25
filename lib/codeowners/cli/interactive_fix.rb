# frozen_string_literal: true

require 'forwardable'
require_relative 'interactive_helpers'
require_relative './helpers/assign_file_owner'
require_relative './helpers/add_pattern_into_group'
require_relative './helpers/suggest_subgroup_for_pattern'

module Codeowners
  module Cli
    # Command Line Interface which covers dialogues and logic
    # that are specific for adding new pattern.
    #
    # Process:
    #
    # - Program will ask if need to add owner for new file detected or ignore it.
    #
    #   EG:
    #
    #     File added: "new_file.rb". Add owner to the CODEOWNERS file?
    #     (y) yes
    #     (i) ignore
    #     (q) quit and save
    #     [y, i, q]
    #
    # - if user prompts (y)es, then:
    #
    #   - program will point user into 'choose owner' and 'new file pattern generation'
    #     (via Helpers::AssignFileOwner class)
    #
    #   - if new file pattern generated successfully, then program will
    #     call Helpers::AddPatternIntoGroup class, where it will:
    #
    #     - suggest to add new file pattern into one of existing subgroups if there are any owned by selected owner
    #       (via Helpers::SuggestSubgroupForPattern class)
    #
    #     - or will ask to assign pattern to main group (end of the CODEOWNERS file)
    #
    # - if user prompts (i)gnore, then
    #   program will returns from #suggest_add_to_codeowners method.
    #
    # - if user prompts (q)uit, then whole program will be interrupted.
    #
    # INPUT:
    #   New detected file path ('test.rb', 'lib/tasks/generate.rake' so on)
    #
    # OUTPUT:
    #   we are not returning specific value here, just executing list of commands.
    #
    class InteractiveFix < Base
      extend Forwardable
      include InteractiveHelpers

      attr_accessor :cli
      attr_reader :content_changed

      no_commands do
        def suggest_add_to_codeowners(file)
          case add_to_codeowners_dialog(file)
          when 'y' then add_to_codeowners(file)
          when 'i' then nil
          when 'q' then throw :user_quit
          end
        end

        def main_group
          checker.main_group
        end

        private

        def_delegators :cli, :checker, :options, :owners_list_handler

        def add_to_codeowners_dialog(file)
          ask(<<~QUESTION, limited_to: %w[y i q])
            File added: #{file.inspect}. Add owner to the CODEOWNERS file?
            (y) yes
            (i) ignore
            (q) quit and save
          QUESTION
        end

        def add_to_codeowners(file)
          pattern = Helpers::AssignFileOwner.new(self, file).pattern
          Helpers::AddPatternIntoGroup.new(self, pattern).run

          @content_changed = true
        end
      end
    end
  end
end
