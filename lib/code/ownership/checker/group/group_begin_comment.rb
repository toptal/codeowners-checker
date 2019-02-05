# frozen_string_literal: true

require_relative 'comment'

module Code
  module Ownership
    class Checker
      class Group
        class GroupBeginComment < Comment
          def self.match?(line)
            line.lstrip.start_with?(/^#+ BEGIN/)
          end
        end
      end
    end
  end
end
