# frozen_string_literal: true

require 'code/ownership/checker/group/line'

RSpec.describe Code::Ownership::Checker::Group::Line do
  describe '.build' do
    subject { described_class.build(line) }

    {
      '# Comment' => Code::Ownership::Checker::Group::Comment,
      '## Comment' => Code::Ownership::Checker::Group::Comment,
      '' => Code::Ownership::Checker::Group::Empty,
      '# BEGIN' => Code::Ownership::Checker::Group::GroupBeginComment,
      '## BEGIN' => Code::Ownership::Checker::Group::GroupBeginComment,
      '# END' => Code::Ownership::Checker::Group::GroupEndComment,
      '## END' => Code::Ownership::Checker::Group::GroupEndComment,
      'pattern @owner' => Code::Ownership::Checker::Group::Pattern,
      'pattern @owner @owner1 @owner2' => Code::Ownership::Checker::Group::Pattern,
      'unrecognized_line' => Code::Ownership::Checker::Group::UnrecognizedLine
    }.each do |content, klass|
      context "when the line is #{content.inspect}" do
        let(:line) { content }

        it { is_expected.to be_an_instance_of(klass) }
      end
    end
  end

  describe '#to_s' do
    subject { described_class.build(line).to_s }

    {
      '# Comment' => '# Comment',
      '## BEGIN' => '## BEGIN',
      '# END' => '# END',
      'pattern @owner @owner1' => 'pattern @owner @owner1',
      '' => ''
    }.each do |content, string|
      context "when the line is #{content.inspect}" do
        let(:line) { content }

        it { is_expected.to eq(string) }
      end
    end
  end
end
