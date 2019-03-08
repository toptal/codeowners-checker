# frozen_string_literal: true

require_relative 'line'

module Codeowners
  class Checker
    class Group
      # Defines and manages line type pattern.
      class Pattern < Line
        attr_accessor :pattern, :owners, :whitespace

        def self.match?(line)
          _pattern, *owners = line.split(/\s+/)
          owners.any? && owners.all? { |owner| owner.include?('@') }
        end

        def initialize(line)
          super
          parse(line)
        end

        def owner
          owners.first
        end

        def parse(line)
          @pattern, *@owners = line.split(/\s+/)
          @whitespace = line.split('@').first.count(' ')
        end

        def match_file?(file)
          if !pattern.include?('/') || pattern.include?('**')
            File.fnmatch(pattern.gsub(%r{^/}, ''), file, File::FNM_DOTMATCH)
          else
            File.fnmatch(pattern.gsub(%r{^/}, ''), file, File::FNM_PATHNAME | File::FNM_DOTMATCH)
          end
        end

        def to_s
          [@pattern, @owners].join(' ')
        end

        def to_file
          pattern + ' ' * [1, whitespace].max + owners.join(' ')
        end
      end
    end
  end
end
