# frozen_string_literal: true

require 'code/ownership/checker/parentable'

module Code
  module Ownership
    class Checker
      class Group
        class Line
          include Parentable

          def self.build(line)
            [Empty, GroupBeginComment, GroupEndComment, Comment, Pattern].each do |klass|
              return klass.new(line) if klass.match?(line)
            end
            UnrecognizedLine.new(line)
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

          def to_tree(indentation = '  ', level = 0)
            indentation * level + to_s
          end

          def ==(other)
            return false unless other.is_a?(self.class)

            other.to_s == to_s
          end
        end
      end
    end
  end
end

require_relative 'comment'
require_relative 'empty'
require_relative 'pattern'
require_relative 'unrecognized_line'
