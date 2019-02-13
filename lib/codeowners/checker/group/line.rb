# frozen_string_literal: true

require_relative '../parentable'
module Codeowners
  class Checker
    class Group
      # It sorts lines from CODEOWNERS file to different line types and holds
      # shared methods for all lines.
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

        def pattern?
          is_a?(Pattern)
        end

        def to_tree(indentation)
          indentation + to_s
        end

        def ==(other)
          return false unless other.is_a?(self.class)

          other.to_s == to_s
        end

        def <=>(other)
          to_s <=> other.to_s
        end

        # Pick all files from parent folder of pattern.
        # This is used to build a list of suggestions case the pattern is not
        # matching.
        # If the pattern use "*/*" it will consider "."
        # If the pattern uses Static files, it tries to reach the parent.
        # If the pattern revers to the root folder, pick all files from the
        # current pattern dir.
        def suggest_files_for_pattern
          parent_folders = pattern.split('/')[0..-2]
          parent_folders << '*' if parent_folders[-1] != '*'
          files = Dir[File.join(*parent_folders)] || []
          files.map(&method(:normalize_path))
        end

        def normalize_path(file)
          Pathname.new(file)
                  .relative_path_from(Pathname.new('.')).to_s
        end
      end
    end
  end
end

require_relative 'empty'
require_relative 'comment'
require_relative 'pattern'
require_relative 'unrecognized_line'
