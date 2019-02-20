# frozen_string_literal: true

require_relative 'line'

module Codeowners
  class Checker
    class Group
      # It sorts lines from CODEOWNERS file to different line types and holds
      # shared methods for all lines.
      class LinkedLine < Line
        attr_accessor :parent_file

        def remove!
          super
          parent_file&.remove(self)
          self.parent_file = nil
        end
      end
    end
  end
end

require_relative 'empty'
require_relative 'comment'
require_relative 'pattern'
require_relative 'unrecognized_line'
