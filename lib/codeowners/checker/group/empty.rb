# frozen_string_literal: true

module Codeowners
  class Checker
    class Group
      # Define line type empty line.
      class Empty < Line
        def self.match?(line)
          line.empty?
        end
      end
    end
  end
end
