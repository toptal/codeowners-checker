# frozen_string_literal: true

require_relative '../interactive_ops'

module Codeowners
  module Cli
    module Wizards
      # Suggests to add new owners to the owners list.
      # Only returns decision without applying any modifications.
      class NewOwnerWizard
        include InteractiveOps

        def suggest_adding(line, new_owner)
          case prompt(line, new_owner)
          when 'y' then :add
          when 'i' then :ignore
          when 'q' then :quit
          end
        end

        private

        def prompt(line, new_owner)
          ask(<<~QUESTION, limited_to: %w[y i q])
            Unknown owner: #{new_owner} for pattern: #{line.pattern}. Add owner to the OWNERS file?
            (y) yes
            (i) ignore owner in this session
            (q) quit and save
          QUESTION
        end
      end
    end
  end
end
