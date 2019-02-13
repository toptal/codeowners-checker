# frozen_string_literal: true

require 'codeowners/checker/group/comment'

RSpec.describe Codeowners::Checker::Group::Comment do
  describe '.level' do
    subject { described_class.build(line).level }

    {
      '# Comment' => 1,
      '## Comment2' => 2,
      '###' => 3
    }.each do |comment, level|
      context "when the comment is #{comment}" do
        let(:line) { comment }

        it { is_expected.to eq(level) }
      end
    end
  end

  describe '#match?' do
    subject { match?(line) }

    context 'with valid comment' do
      it { expect(described_class).to be_match('# header') }
      it { expect(described_class).to be_match('## sub-header') }
    end

    context 'with invalid comment' do
      it { expect(described_class).not_to be_match(' # starting with space') }
    end
  end
end
