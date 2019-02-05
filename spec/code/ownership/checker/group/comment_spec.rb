# frozen_string_literal: true

require 'code/ownership/checker/group/comment'

RSpec.describe Code::Ownership::Checker::Group::Comment do
  describe '.level' do
    subject { described_class.build(line).level }

    {
      '# Comment' => 1,
      '## Comment2' => 2,
      '  # Comment3' => 1,
      '###' => 3
    }.each do |comment, level|
      context "when the comment is #{comment}" do
        let(:line) { comment }

        it { is_expected.to eq(level) }
      end
    end
  end
end
