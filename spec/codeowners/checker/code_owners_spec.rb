# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

require 'codeowners/checker/code_owners'

RSpec.describe Codeowners::Checker::CodeOwners do
  let(:pattern) { Codeowners::Checker::Group::Line.build('pattern @owner') }

  let(:example_content) do
    [
      '#comment1',
      '#comment2',
      '',
      '',
      '#group1',
      'pattern @owner',
      'pattern2 @owner',
      'pattern3 @owner',
      '',
      'pattern10 @owner2',
      'pattern11 @owner2',
      '',
      '#group2',
      'pattern4 @owner1',
      'pattern5 @owner2',
      'pattern6 @owner1 @owner2',
      '',
      '# BEGIN group 3',
      '#comment3',
      '',
      '##group3.1',
      'pattern7 @owner3',
      '',
      'pattern71 @owner2',
      '',
      '##group3.2',
      'pattern8 @owner',
      '',
      'pattern9 @owner',
      '',
      '# END group 3'
    ]
  end

  let(:example_group) { Codeowners::Checker::Group.new }

  def add_content(group, text)
    group.add(Codeowners::Checker::Group::Line.build(text))
  end

  before do
    comments_group = Codeowners::Checker::Group.new
    add_content(comments_group, '#comment1')
    add_content(comments_group, '#comment2')
    add_content(comments_group, '')
    add_content(comments_group, '')
    example_group.add(comments_group)

    group1 = Codeowners::Checker::Group.new
    add_content(group1, '#group1')
    group1.add(pattern)
    add_content(group1, 'pattern2 @owner')
    add_content(group1, 'pattern3 @owner')
    add_content(group1, '')
    example_group.add(group1)

    no_name = Codeowners::Checker::Group.new
    add_content(no_name, 'pattern10 @owner2')
    add_content(no_name, 'pattern11 @owner2')
    add_content(no_name, '')
    example_group.add(no_name)

    group2 = Codeowners::Checker::Group.new
    add_content(group2, '#group2')
    add_content(group2, 'pattern4 @owner1')
    add_content(group2, 'pattern5 @owner2')
    add_content(group2, 'pattern6 @owner1 @owner2')
    add_content(group2, '')
    example_group.add(group2)

    group3 = Codeowners::Checker::Group.new
    add_content(group3, '# BEGIN group 3')
    add_content(group3, '#comment3')
    add_content(group3, '')
    group3_1 = Codeowners::Checker::Group.new
    add_content(group3_1, '##group3.1')
    add_content(group3_1, 'pattern7 @owner3')
    add_content(group3_1, '')
    group3.add(group3_1)
    group3_no_name = Codeowners::Checker::Group.new
    add_content(group3_no_name, 'pattern71 @owner2')
    add_content(group3_no_name, '')
    group3.add(group3_no_name)
    group3_2 = Codeowners::Checker::Group.new
    add_content(group3_2, '##group3.2')
    add_content(group3_2, 'pattern8 @owner')
    add_content(group3_2, '')
    add_content(group3_2, 'pattern9 @owner')
    add_content(group3_2, '')
    group3.add(group3_2)
    add_content(group3, '# END group 3')
    example_group.add(group3)
  end

  describe '#initialize' do
    subject { described_class.new(file_manager) }

    let(:file_manager) { double }

    it 'parses the content into groups of lines' do
      expect(file_manager).to receive(:content).and_return(example_content)
      expect(subject.list).to all(be_kind_of(Codeowners::Checker::Group::Line))
    end
  end

  describe '#remove' do
    subject { described_class.new(file_manager) }

    let(:file_manager) { double }

    it 'removes line from the list' do
      expect(file_manager).to receive(:content).and_return(example_content)
      subject.remove(pattern)
      expect(subject.list.map(&:to_content)).to eq(
        ['#comment1', '#comment2', '', '', '#group1', 'pattern2 @owner', 'pattern3 @owner',
         '', 'pattern10 @owner2', 'pattern11 @owner2', '', '#group2', 'pattern4 @owner1',
         'pattern5 @owner2', 'pattern6 @owner1 @owner2', '', '# BEGIN group 3', '#comment3',
         '', '##group3.1', 'pattern7 @owner3', '', 'pattern71 @owner2', '', '##group3.2',
         'pattern8 @owner', '', 'pattern9 @owner', '', '# END group 3']
      )
    end
  end

  describe '#insert_after' do
    subject { described_class.new(file_manager) }

    let(:file_manager) { double }
    let(:new_line) { Codeowners::Checker::Group::Line.build('pattern1 @owner') }

    it 'inserts new record to codeowners after particular line' do
      expect(file_manager).to receive(:content).and_return(example_content)
      subject.insert_after(pattern, new_line)
      expect(subject.list.map(&:to_content)).to eq(
        ['#comment1', '#comment2', '', '', '#group1', 'pattern @owner', 'pattern1 @owner',
         'pattern2 @owner', 'pattern3 @owner', '', 'pattern10 @owner2', 'pattern11 @owner2',
         '', '#group2', 'pattern4 @owner1', 'pattern5 @owner2', 'pattern6 @owner1 @owner2',
         '', '# BEGIN group 3', '#comment3', '', '##group3.1', 'pattern7 @owner3', '',
         'pattern71 @owner2', '', '##group3.2', 'pattern8 @owner', '', 'pattern9 @owner', '',
         '# END group 3']
      )
    end
  end
end
