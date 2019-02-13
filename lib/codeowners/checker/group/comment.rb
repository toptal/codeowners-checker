# frozen_string_literal: true

require_relative 'line'

module Codeowners
  class Checker
    class Group
      # Define and manage comment line.
      class Comment < Line
        # Matches if the line is a comment.
        # @return [Boolean] if the line start with `#`
        def self.match?(line)
          line.start_with?('#')
        end

        # Return the comment level if the comment works like a markdown
        # headers.
        # @return [Integer] with the heading level.
        #
        # @example
        #   Comment.new('# First level').level # => 1
        #   Comment.new('## Second').level # => 2
        def level
          (@line[/^#+/] || '').size
        end
      end
    end
  end
end

require_relative 'group_begin_comment'
require_relative 'group_end_comment'
