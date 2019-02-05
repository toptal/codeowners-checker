# frozen_string_literal: true

require_relative 'comment'

module Code
  module Ownership
    class Checker
      class Group
        class GroupEndComment < Comment
          def self.match?(line)
            line.lstrip.start_with?(/^#+ END/)
          end
        end
      end
    end
  end
end
