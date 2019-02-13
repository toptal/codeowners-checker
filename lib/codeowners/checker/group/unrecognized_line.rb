# frozen_string_literal: true

module Codeowners
  class Checker
    class Group
      # Hold lines which are not defined in other line classes.
      class UnrecognizedLine < Line
      end
    end
  end
end
