# frozen_string_literal: true

module Codeowners
  class Checker
    # Convert CODEOWNERS file content to an array.
    class FileAsArray
      attr_writer :content
      attr_reader :filename

      def initialize(filename)
        @filename = filename
        @target_dir, = File.split(@filename)
      end

      # @return <Array> of lines chomped
      def content
        @content ||= File.readlines(@filename).map(&:chomp)
      rescue Errno::ENOENT
        @content = []
      end

      # Save content to the @file
      # Creates the directory of the file if needed
      def persist!
        Dir.mkdir(@target_dir) unless Dir.exist?(@target_dir)

        File.open(@filename, 'w+') do |f|
          f.puts content
        end
      end
    end
  end
end
