# frozen_string_literal: true

module Code
  module Ownership
    # Check code ownership is consistent between a git repository and
    # Parse .github/CODEOWNERS content into Ownership that is a
    # Struct.new(:pattern, :regex, :owners, :line, :comments)
    # It parses and attach previous comments to the content
    # to allow us to rewrite the file in the future.
    class CodeOwnersFile
      attr_reader :owners
      def initialize(content)
        @content = content
        @owners = []
        @comments = []
      end

      def parse!
        @content.each_with_index do |line, i|
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

      def process_ownership(line)
        pattern, *owners = line.chomp.split(/\s+/)
        @owners << Code::Ownership::Record.new(pattern, owners, @line_number, @comments)
        @comments = []
      end

      def find_record(line:)
        @owners.find { |record| record.line == line }
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

        raise "no patterns with line: #{line}" if index.nil?

        @owners.insert index, Code::Ownership::Record.new(pattern, owners, after_line + 1, comments)
      end

      def delete(line:)
        record = find_record line: line
        @owners.delete(record) || raise("couldn't find record with line #{line}")
      end

      def process_content!
        @owners.uniq!
        @content = @owners.map(&:to_row).join("\n")
      end
    end
  end
end
