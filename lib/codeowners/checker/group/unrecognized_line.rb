# frozen_string_literal: true

require_relative 'linked_line'

module Codeowners
  class Checker
    class Group
      # Hold lines which are not defined in other line classes.
      class UnrecognizedLine < LinkedLine
      end
    end
  end
end
