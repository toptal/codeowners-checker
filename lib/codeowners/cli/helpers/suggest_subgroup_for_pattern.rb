# frozen_string_literal: true

require 'forwardable'

module Codeowners
  module Cli
    module Helpers
      # This class covers 'suggestion of subgroups for pattern' process:
      #
      # - If there are any existing subgroups which are belong to selected new file owner, then
      #   it shows 'suggestion dialog' with ordered list of subgroups to select.
      #
      #   EG:
      #
      #     Owners:
      #     1 - @company/backend
      #     2 - @company/frontend
      #     Choose owner, add new one or leave empty to use "@company/backend".
      #     New owner:  2
      #     Possible groups to which the pattern belongs:
      #     1 - # @company/backend - API
      #     2 - # @company/backend - WEB
      #     3 - # @company/backend - Billing
      #     Choose group:
      #
      #   If prompted number of subgroup is valid, then
      #   program inserts new pattern into selected subgroup.
      #
      # - If there are no any subgroups to suggest or prompted number of subgroup
      #   is wrong, then program returns #run method.
      #
      # INPUT:
      #   instance of ::Codeowners::Cli::InteractiveFix
      #   as we need to access several dependencies through it:
      #
      #   - main_group' object
      #   - and 'ask' CLI method
      #
      # OUTPUT:
      #   we are not returning specific value here, just executing list of commands.
      #
      class SuggestSubgroupForPattern
        extend Forwardable

        def initialize(interactive_fix, pattern)
          @interactive_fix = interactive_fix
          @pattern = pattern
        end

        def run
          return if subgroups.empty?

          show_suggestion_dialog
          return unless selected_subgroup_index_is_valid?

          @success = subgroups[selected_subgroup_index].insert(pattern)
        end

        def success?
          @success
        end

        private

        def_delegators :@interactive_fix, :main_group, :ask
        attr_reader :pattern, :selected_subgroup_index

        def show_suggestion_dialog
          subgroup_names = subgroups.map.with_index do |group, i|
            "#{i + 1} - #{group.title}"
          end.join("\n")

          template = <<~OUTPUT
            Possible groups to which the pattern belongs:
            %<subgroups_list>s
          OUTPUT
          puts format(template, subgroups_list: subgroup_names)

          @selected_subgroup_index = ask('Choose group: ').to_i - 1
        end

        def selected_subgroup_index_is_valid?
          (0...subgroups.length).cover?(selected_subgroup_index)
        end

        def subgroups
          @subgroups ||= main_group.subgroups_owned_by(pattern.owner)
        end
      end
    end
  end
end
