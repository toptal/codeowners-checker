# frozen_string_literal: true

require 'pathname'
module Codeowners
  class Checker
    class Group
      # It sorts lines from CODEOWNERS file to different line types and holds
      # shared methods for all lines.
      class Line
        attr_accessor :parent

        def self.build(line)
          subclasses.each do |klass|
            return klass.new(line) if klass.match?(line)
          end
          UnrecognizedLine.new(line)
        end

        def self.subclasses
          [Empty, GroupBeginComment, GroupEndComment, Comment, Pattern]
        end

        def initialize(line)
          @line = line
        end

        def to_s
          @line
        end

        def to_content
          to_s
        end

        def to_file
          to_s
        end

        def pattern?
          is_a?(Pattern)
        end

        def to_tree(indentation)
          indentation + to_s
        end

        def remove!
          parent&.remove(self)
          self.parent = nil
        end

        def ==(other)
          return false unless other.is_a?(self.class)

          other.to_s == to_s
        end

        def <=>(other)
          to_s <=> other.to_s
        end
      end
    end
  end
end

require_relative 'empty'
require_relative 'comment'
require_relative 'pattern'
require_relative 'unrecognized_line'
