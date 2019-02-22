# frozen_string_literal: true

require 'codeowners/checker/group/line'

RSpec.describe Codeowners::Checker::Group::Line do
  describe '.build' do
    subject { described_class.build(line) }

    {
      '# Comment' => Codeowners::Checker::Group::Comment,
      '## Comment' => Codeowners::Checker::Group::Comment,
      '' => Codeowners::Checker::Group::Empty,
      '# BEGIN' => Codeowners::Checker::Group::GroupBeginComment,
      '## BEGIN' => Codeowners::Checker::Group::GroupBeginComment,
      '# END' => Codeowners::Checker::Group::GroupEndComment,
      '## END' => Codeowners::Checker::Group::GroupEndComment,
      'pattern @owner' => Codeowners::Checker::Group::Pattern,
      'pattern @owner @owner1 @owner2' => Codeowners::Checker::Group::Pattern,
      'unrecognized_line' => Codeowners::Checker::Group::UnrecognizedLine
    }.each do |content, klass|
      context "when the line is #{content.inspect}" do
        let(:line) { content }

        it { is_expected.to be_an_instance_of(klass) }
      end
    end
  end

  describe '.subclasses' do
    let(:line_subclasses) do
      ObjectSpace.each_object(::Class).select { |klass| klass < described_class } - [
        Codeowners::Checker::Group::UnrecognizedLine
      ]
    end

    it 'includes all subclasses except of unrecognized line' do
      expect(described_class.subclasses).to match_array(line_subclasses)
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
