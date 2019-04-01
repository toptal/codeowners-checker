# frozen_string_literal: true

require_relative 'line'
require_relative '../owner'

module Codeowners
  class Checker
    class Group
      # Defines and manages line type pattern.
      # Parse the line into pattern, owners and whitespaces.
      class Pattern < Line
        attr_accessor :owners, :whitespace
        attr_reader :pattern

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

        # Parse the line counting whitespaces between pattern and owners.
        def parse(line)
          @pattern, *@owners = line.split(/\s+/)
          @whitespace = line.split('@').first.count(' ') - 1
        end

        def match_file?(file)
          if !pattern.include?('/') || pattern.include?('**')
            File.fnmatch(pattern.gsub(%r{^/}, ''), file, File::FNM_DOTMATCH)
          else
            File.fnmatch(pattern.gsub(%r{^/}, ''), file, File::FNM_PATHNAME | File::FNM_DOTMATCH)
          end
        end

        def pattern=(new_pattern)
          @whitespace += @pattern.size - new_pattern.size
          @whitespace = 1 if @whitespace < 1

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
      end
    end
  end
end
