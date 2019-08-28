# frozen_string_literal: true

require_relative 'comment'

module Codeowners
  class Checker
    class Group
      # Define line type GroupEndComment which is used for defining the end
      # of a group.
      class GroupEndComment < Comment
        def self.match?(line)
          line.lstrip =~ /^#+ END/
        end
      end
    end
  end
end
