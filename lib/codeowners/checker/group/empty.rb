# frozen_string_literal: true

require_relative 'linked_line'

module Codeowners
  class Checker
    class Group
      # Define line type empty line.
      class Empty < LinkedLine
        def self.match?(line)
          line.empty?
        end
      end
    end
  end
end
