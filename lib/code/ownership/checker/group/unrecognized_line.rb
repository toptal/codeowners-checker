# frozen_string_literal: true

require_relative 'line'

module Code
  module Ownership
    class Checker
      class Group
        # Hold lines which are not defined in other line classes.
        class UnrecognizedLine < Line
        end
      end
    end
  end
end
