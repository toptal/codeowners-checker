# frozen_string_literal: true

require_relative '../interactive_ops'

module Codeowners
  module Cli
    module Wizards
      # Suggests to fix useless patterns in the codeowners file.
      # Only returns decision without applying any modifications.
      class UselessPatternWizard
        include InteractiveOps

        def suggest_fixing(line)
          puts "Pattern #{line.pattern.inspect} doesn't match."
          suggestion = Codeowners::Cli::SuggestFileFromPattern.new(line.pattern).pick_suggestion

          # TODO: Handle duplicate patterns.
          if suggestion
            apply_suggestion(line, suggestion)
          else
            pattern_fix(line)
          end
        end

        private

        def apply_suggestion(line, suggestion)
          case make_suggestion(suggestion)
          when 'i' then :ignore
          when 'y' then [:replace, suggestion]
          when 'e' then edit_pattern(line)
          when 'd' then :delete
          when 'q' then :quit
          end
        end

        def make_suggestion(suggestion)
          ask(<<~QUESTION, limited_to: %w[y i e d q])
            Replace with: #{suggestion.inspect}?
            (y) yes
            (i) ignore
            (e) edit the pattern
            (d) delete the pattern
            (q) quit and save
          QUESTION
        end

        def pattern_fix(line)
          case pattern_suggest_fixing
          when 'e' then edit_pattern(line)
          when 'i' then :ignore
          when 'd' then :delete
          when 'q' then :quit
          end
        end

        def pattern_suggest_fixing
          ask(<<~QUESTION, limited_to: %w[i e d q])
            (e) edit the pattern
            (d) delete the pattern
            (i) ignore
            (q) quit and save
          QUESTION
        end

        def edit_pattern(line)
          new_pattern = ask("Replace pattern #{line.pattern.inspect} with: ")
          return :nop if new_pattern.empty?

          [:replace, new_pattern]
        end
      end
    end
  end
end
