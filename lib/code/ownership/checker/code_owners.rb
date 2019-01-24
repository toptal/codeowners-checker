# frozen_string_literal: true

require 'code/ownership/record'

module Code
  module Ownership
    class Checker
      # Check code ownership is consistent between a git repository and
      # Parse .github/CODEOWNERS content into Ownership that is a
      # Struct.new(:pattern, :regex, :owners, :line, :comments)
      # It parses and attach previous comments to the content
      # to allow us to rewrite the file in the future.
      class CodeOwners
        attr_reader :owners

        def initialize(file_manager)
          @file_manager = file_manager
          @owners = []
          @comments = []
        end

        def parse!
          content.each_with_index do |line, i|
            next if line.nil?

            if line.match?(/^\s*#|^$/)
              @comments << line.chomp
              next
            end
            @line_number = i + 1
            process_ownership line
          end
          @owners
        end

        def persist!
          @file_manager.content = process_content!

          # We need to reparse the file after changes have been made,
          # to make sure the line numbers are correct
          parse!
        end

        def update(line:, pattern: nil, owners: nil, comments: nil)
          record = find_record line: line

          raise "no patterns with line: #{line}" if record.nil?

          record.pattern = pattern if pattern
          record.owners = owners if owners
          record.comments = comments if comments
        end

        def insert(after_line:, pattern: nil, owners: nil, comments: nil)
          index = @owners.index { |record| record.line == after_line }

          raise "no patterns with line: #{after_line}" if index.nil?

          @owners.insert index, Code::Ownership::Record.new(pattern, owners, after_line + 1, comments)
        end

        def append(pattern:, owners:, comments: nil)
          line = @owners.last.line
          @owners.push Code::Ownership::Record.new(pattern, owners, line + 1, comments)
        end

        def delete(line:)
          record = find_record line: line
          @owners.delete(record) || raise("couldn't find record with line #{line}")
        end

        private

        def content
          @content ||= @file_manager.content
        end

        def process_content!
          @owners.uniq!
          @content = @owners.flat_map(&:to_row)
        end

        def process_ownership(line)
          pattern, *owners = line.chomp.split(/\s+/)
          pattern.sub!(%r{^/}, '')
          @owners << Code::Ownership::Record.new(pattern, owners, @line_number, @comments)
          @comments = []
        end

        def find_record(line:)
          @owners.find { |record| record.line == line }
        end
      end
    end
  end
end
