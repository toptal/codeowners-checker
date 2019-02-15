# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

require 'codeowners/checker/code_owners'

RSpec.describe Codeowners::Checker::CodeOwners do
  subject { described_class.new(file_manager) }

  let(:file_manager) { double }

  let(:example_content) do
    [
      '#comment1',
      '',
      '',
      '#group1',
      '#comment1',
      'pattern @owner',
      'pattern2 @owner',
      'pattern @owner',
      ''
    ]
  end

  let(:example_lines) do
    [
      Codeowners::Checker::Group::Comment.new('#comment1'),
      Codeowners::Checker::Group::Empty.new(''),
      Codeowners::Checker::Group::Empty.new(''),
      Codeowners::Checker::Group::Comment.new('#group1'),
      Codeowners::Checker::Group::Comment.new('#comment1'),
      Codeowners::Checker::Group::Pattern.new('pattern @owner'),
      Codeowners::Checker::Group::Pattern.new('pattern2 @owner'),
      Codeowners::Checker::Group::Pattern.new('pattern @owner'),
      Codeowners::Checker::Group::Empty.new('')
    ]
  end

  describe '#initialize' do
    it 'parses the content into groups of lines' do
      expect(file_manager).to receive(:content).and_return(example_content)
      expect(subject.list).to eq(example_lines)
    end
  end

  describe '#remove' do
    let(:pattern) { subject.list[5] }
    let(:comment) { subject.list[4] }
    let(:empty_line) { subject.list[2] }

    it 'removes line from the list' do
      expect(file_manager).to receive(:content).and_return(example_content)
      pattern.remove!
      comment.remove!
      empty_line.remove!
      expect(subject.to_content).to eq(
        ['#comment1', '', '#group1', 'pattern2 @owner', 'pattern @owner', '']
      )
    end
  end

  describe '#insert_after' do
    let(:new_line) { Codeowners::Checker::Group::Line.build('pattern1 @owner') }
    let(:pattern) { example_lines[5] }

    it 'inserts new record to codeowners after particular line' do
      expect(file_manager).to receive(:content).and_return(example_content)
      subject.insert_after(pattern, new_line)
      expect(subject.to_content).to eq(
        ['#comment1', '', '', '#group1', '#comment1', 'pattern @owner',
         'pattern1 @owner', 'pattern2 @owner', 'pattern @owner', '']
      )
    end
  end
end
