# frozen_string_literal: true

require_relative '../interactive_ops'

module Codeowners
  module Cli
    module Wizards
      # Suggests to fix unrecognized lines in the codeowners file.
      # Only returns decision without applying any modifications.
      class UnrecognizedLineWizard
        include InteractiveOps

        def suggest_fixing(line)
          case prompt(line)
          when 'i' then :ignore
          when 'y' then [:replace, keep_asking_until_valid_line]
          when 'd' then :delete
          end
        end

        private

        def prompt(line)
          ask(<<~QUESTION, limited_to: %w[y i d])
            #{line.to_s.inspect} is in unrecognized format. Would you like to edit?
            (y) yes
            (i) ignore
            (d) delete the line
          QUESTION
        end

        def keep_asking_until_valid_line
          line = nil
          loop do
            new_line_string = ask('New line: ')
            line = Codeowners::Checker::Group::Line.build(new_line_string)
            break unless line.is_a?(Codeowners::Checker::Group::UnrecognizedLine)
          end
          line
        end
      end
    end
  end
end
