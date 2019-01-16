# frozen_string_literal: true

require 'pathname'
module Code
  module Ownership
    # Record represents a single row of the .github/CODEOWNERS file
    # It also builds the same patter on #to_row to allow dump it back
    # to the file.
    # The #comments are useful for restoring previous comments in the file in
    # case of rewriting the file.
    class Record < Struct.new(:pattern, :owners, :line, :comments)
      # Returns a regex based on the pattern included in each row.
      def regex
        Regexp.new(pattern.gsub(%r{/\*\*}, '(/[^/]+)+').gsub(/\*/, '[^/]+'))
      end

      # Returns a String that can be dumped into CODEOWNERS file again
      def to_row
        [
          *comments,
          [pattern, owners].join(' ')
        ].join("\n")
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
