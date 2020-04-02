# frozen_string_literal: true

require 'pathspec'

module Codeowners
  class Checker
    # Manage CODEOWNERS_WHITELIST file reading
    class Whitelist
      def initialize(filename)
        @filename = filename
      end

      def exist?
        File.exist?(@filename)
      end

      def whitelisted?(filename)
        pathspec.match(filename)
      end

      def to_proc
        proc { |item| whitelisted?(item) }
      end

      private

      def pathspec
        @pathspec = if File.exist?(@filename)
                      PathSpec.from_filename(@filename)
                    else
                      PathSpec.new([])
                    end
      end
    end
  end
end
