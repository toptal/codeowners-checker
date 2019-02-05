# frozen_string_literal: true

require_relative 'line'

module Code
  module Ownership
    class Checker
      class Group
        class Comment < Line
          def self.match?(line)
            line.lstrip.start_with?('#')
          end

          def level
            striped_line = @line.lstrip

            striped_line.each_char.with_index do |char, index|
              return index if char != '#'
              return index + 1 if striped_line.length == index + 1
            end
            0
          end
        end
      end
    end
  end
end

require_relative 'group_begin_comment'
require_relative 'group_end_comment'
