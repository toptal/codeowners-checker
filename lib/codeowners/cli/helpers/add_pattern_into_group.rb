# frozen_string_literal: true

require 'forwardable'

module Codeowners
  module Cli
    module Helpers
      # This class covers 'adding of new pattern' process:
      #
      # - into one of existing subgroups which are belong to selected owner of new file
      #   (via 'Helpers::SuggestSubgroupForPattern' class)
      #
      #   EG:
      #
      #     Owners:
      #     1 - @toptal/bootcamp
      #     2 - @toptal/ninjas
      #     Choose owner, add new one or leave empty to use "@toptal/bootcamp".
      #     New owner:  2
      #     Possible groups to which the pattern belongs:
      #     1 - # Ninjas - Top
      #     2 - # Ninjas - Middle
      #     3 - # Ninjas - Bottom
      #     Choose group:
      #
      # - or into main group (end of the CODEOWNERS file) in case if there are no any existing
      #   subgroups owned by specified owner or in case if prompted subgroup number do not much
      #   any of shown suggestions (selection is invalid).
      #
      #   EG:
      #
      #     Add to the end of the CODEOWNERS file?
      #
      # INPUT:
      #   instance of ::Codeowners::Cli::InteractiveFix
      #   as we need to access several dependencies through it:
      #
      #   - main_group' object
      #   - and 'yes?' CLI method
      #
      # OUTPUT:
      #   we are not returning specific value here, just executing list of commands
      #
      class AddPatternIntoGroup
        extend Forwardable

        def initialize(interactive_fix, pattern)
          @interactive_fix = interactive_fix
          @pattern = pattern
        end

        def run
          suggesting_interactor.run
          return if suggesting_interactor.success?

          main_group.add(pattern) if yes?('Add to the end of the CODEOWNERS file?')
        end

        private

        def_delegators :@interactive_fix, :main_group, :yes?
        attr_reader :pattern

        def suggesting_interactor
          @suggesting_interactor ||= SuggestSubgroupForPattern.new(@interactive_fix, pattern)
        end
      end
    end
  end
end
