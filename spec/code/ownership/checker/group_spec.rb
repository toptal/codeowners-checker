# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

require 'code/ownership/checker/group'

RSpec.describe Code::Ownership::Checker::Group do
  subject { described_class.new }
end
