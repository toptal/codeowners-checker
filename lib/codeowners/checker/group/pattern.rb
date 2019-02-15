# frozen_string_literal: true

module Codeowners
  class Checker
    class Group
      # Defines and manages line type pattern.
      class Pattern < Line
        attr_accessor :pattern, :owners

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
        end

        def to_s
          [@pattern, @owners].join(' ')
        end
      end
    end
  end
end
