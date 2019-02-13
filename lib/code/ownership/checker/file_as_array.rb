# frozen_string_literal: true

module Code
  module Ownership
    class Checker
      # Convert CODEOWNERS file content to an array.
      class FileAsArray
        def initialize(file)
          @file = file
          @target_dir, = File.split(@file)
        end

        def content
          @content ||= File.readlines(@file).map(&:chomp)
        rescue Errno::ENOENT
          @content = []
        end

        def content=(content)
          @content = content

          Dir.mkdir(@target_dir) unless Dir.exist?(@target_dir)

          File.open(@file, 'w+') do |f|
            f.puts content
          end
        end
      end
    end
  end
end
