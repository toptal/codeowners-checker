# frozen_string_literal: true

require_relative 'comment'

module Codeowners
  class Checker
    class Group
      # Define line type GroupBeginComment which is used for defining the beggining
      # of a group.
      class GroupBeginComment < Comment
        def self.match?(line)
          line.lstrip =~ /^#+ BEGIN/
        end
      end
    end
  end
end
