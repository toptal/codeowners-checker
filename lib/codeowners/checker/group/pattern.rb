# frozen_string_literal: true

require_relative 'line'
require_relative '../owner'
require 'pathspec'

module Codeowners
  class Checker
    class Group
      # Defines and manages line type pattern.
      # Parse the line into pattern, owners and whitespaces.
      class Pattern < Line
        attr_accessor :owners, :whitespace
        attr_reader :pattern, :spec

        def self.match?(line)
          _pattern, *owners = line.split(/\s+/)
          Owner.valid?(*owners)
        end

        def initialize(line)
          super
          parse(line)
        end

        def owner
          owners.first
        end

        def rename_owner(owner, new_owner)
          owners.delete(owner)
          owners << new_owner unless owners.include?(new_owner)
        end

        # Parse the line counting whitespaces between pattern and owners.
        def parse(line)
          @pattern, *@owners = line.split(/\s+/)
          @whitespace = line.split('@').first.count(' ') - 1
          @spec = parse_spec(@pattern)
        end

        def match_file?(file)
          spec.match file
        end

        def pattern=(new_pattern)
          @whitespace += @pattern.size - new_pattern.size
          @whitespace = 1 if @whitespace < 1

          @spec = parse_spec(new_pattern)
          @pattern = new_pattern
        end

        # @return String with the pattern and owners
        # Use @param preserve_whitespaces to keep the previous identation.
        def to_file(preserve_whitespaces: true)
          line = pattern
          spaces = preserve_whitespaces ? whitespace : 0
          line << ' ' * spaces
          [line, *owners].join(' ')
        end

        def to_s
          to_file(preserve_whitespaces: false)
        end

        def parse_spec(pattern)
          PathSpec.from_lines(pattern)
        end
      end
    end
  end
end
