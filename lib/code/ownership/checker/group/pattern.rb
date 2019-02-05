# frozen_string_literal: true

require_relative 'line'

module Code
  module Ownership
    class Checker
      class Group
        class Pattern < Line
          attr_accessor :pattern, :owners

          def self.match?(line)
            _pattern, *owners = line.split(/\s+/)
            owners.any? && owners.all? { |owner| owner.include?('@') }
          end

          def initialize(line)
            @pattern, *@owners = line.split(/\s+/)
          end

          def to_s
            [@pattern, @owners].join(' ')
          end
        end
      end
    end
  end
end
