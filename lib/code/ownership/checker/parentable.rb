# frozen_string_literal: true

require 'code/ownership/checker/group/line'

module Code
  module Ownership
    class Checker
      module Parentable
        attr_accessor :parent
      end
    end
  end
end
