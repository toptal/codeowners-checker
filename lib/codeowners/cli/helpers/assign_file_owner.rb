# frozen_string_literal: true

require 'forwardable'

module Codeowners
  module Cli
    module Helpers
      # This class covers 'choose owner for new file pattern' process:
      #
      # - If there are any existing owners detected in 'OWNERS' file, then
      #   it shows list of them and asking to choose owner.
      #
      #   You are able also to type a new one or leave blank (in case of usage of default owner).
      #
      #   EG:
      #
      #     Owners:
      #     1 - @company/backend
      #     2 - @company/frontend
      #
      #     Choose owner, add new one or leave empty to use "@company/backend".
      #     New owner:
      #
      # - If there are no any existing owners, then
      #   program will ask to type new one or leave blank (in case of usage of default owner).
      #
      #   EG:
      #
      #     Owners:
      #     Choose owner, add new one or leave empty to use "@company/backend".
      #     New owner:
      #
      # Dialogs and pattern generation process delegated to 'owners_list_handler',
      # which is instance of Codeowners::Cli::OwnersListHandler.
      #
      # INPUT:
      #
      #   Instance of ::Codeowners::Cli::InteractiveFix
      #   as we need to access several dependencies through it:
      #
      #    - 'options' hash
      #    - 'config' and 'main_group' objects
      #    - and 'owners_list_handler'
      #
      # OUTPUT:
      #
      #   proper pattern for new detected file (instance of Codeowners::Checker::Group::Pattern).
      #
      class AssignFileOwner
        extend Forwardable

        def initialize(interactive_fix, file)
          @file = file
          @interactive_fix = interactive_fix
        end

        def pattern
          show_existing_owners
          return owners_list_handler.create_new_pattern_with_validated_owner(file, owners) if options[:validateowners]

          owners_list_handler.create_new_pattern_with_owner(file, owners)
        end

        private

        def_delegators :@interactive_fix, :config, :options, :main_group, :owners_list_handler
        attr_reader :file

        def show_existing_owners
          owner_names = owners.map.with_index do |owner, i|
            "#{i + 1} - #{owner}"
          end.join("\n")

          template = <<~OUTPUT
            Owners:
            %<owners_list>s
            Choose owner, add new one or leave empty to use "%<default_owner>s".
          OUTPUT

          puts format(template, owners_list: owner_names, default_owner: config.default_owner)
        end

        def owners
          @owners ||= main_group.owners.sort
        end
      end
    end
  end
end
