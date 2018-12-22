# frozen_string_literal: true

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

      def to_row
        [
          *comments,
          [pattern, owners].join(' ')
        ].join("\n")
      end
    end
  end
end
