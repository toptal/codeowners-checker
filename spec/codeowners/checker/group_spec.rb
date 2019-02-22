# frozen_string_literal: true

require 'codeowners/checker/group'

RSpec.describe Codeowners::Checker::Group do
  subject { described_class.new }

  let(:comments_group) { described_class.new }
  let(:group1) { described_class.new }
  let(:no_name) { described_class.new }
  let(:group2) { described_class.new }
  let(:group3) { described_class.new }
  let(:group31) { described_class.new }
  let(:pattern) { Codeowners::Checker::Group::Line.build('pattern4 @owner') }
  let(:pattern1) { Codeowners::Checker::Group::Line.build('pattern @owner3') }

  let(:example_content) do
    [
      '#comment1',
      '#comment2',
      '',
      '',
      '#group1',
      'pattern1 @owner',
      'pattern2 @owner',
      'pattern5 @owner',
      '',
      'pattern10 @owner2',
      'pattern11 @owner2',
      '',
      '#group2',
      'pattern4 @owner',
      'pattern5 @owner2',
      'pattern6 @owner @owner2',
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

  def add_content(group, text)
    group.add(Codeowners::Checker::Group::Line.build(text))
  end

  before do
    add_content(comments_group, '#comment1')
    add_content(comments_group, '#comment2')
    add_content(comments_group, '')
    add_content(comments_group, '')
    subject.add(comments_group)

    add_content(group1, '#group1')
    add_content(group1, 'pattern1 @owner')
    add_content(group1, 'pattern2 @owner')
    add_content(group1, 'pattern5 @owner')
    add_content(group1, '')
    subject.add(group1)

    add_content(no_name, 'pattern10 @owner2')
    add_content(no_name, 'pattern11 @owner2')
    add_content(no_name, '')
    subject.add(no_name)

    add_content(group2, '#group2')
    add_content(group2, 'pattern4 @owner')
    add_content(group2, 'pattern5 @owner2')
    add_content(group2, 'pattern6 @owner @owner2')
    add_content(group2, '')
    subject.add(group2)

    add_content(group3, '# BEGIN group 3')
    add_content(group3, '#comment3')
    add_content(group3, '')
    add_content(group31, '##group3.1')
    add_content(group31, 'pattern7 @owner3')
    add_content(group31, '')
    group3.add(group31)
    group3_no_name = described_class.new
    add_content(group3_no_name, 'pattern71 @owner2')
    add_content(group3_no_name, '')
    group3.add(group3_no_name)
    group32 = described_class.new
    add_content(group32, '##group3.2')
    add_content(group32, 'pattern8 @owner')
    add_content(group32, '')
    add_content(group32, 'pattern9 @owner')
    add_content(group32, '')
    group3.add(group32)
    add_content(group3, '# END group 3')
    subject.add(group3)
  end

  describe '#parse' do
    let(:lines) { [] }
    let(:main_group) { described_class.new }

    before do
      example_content.each { |text| lines << Codeowners::Checker::Group::Line.build(text) }
    end

    it 'parses lines from codeowners file to groups and subgroups' do
      main_group.parse(lines)
      expect(main_group).to eq(subject)
      expect(main_group.to_content).to eq(example_content)
    end
  end

  describe '#to_content' do
    it 'dumps the group to content' do
      expect(subject.to_content).to eq(example_content)
    end
  end

  describe '#to_tree' do
    it 'maps the structure of the groups and subgroups into strings' do
      expect(group3.to_tree).to eq([
                                     ' # BEGIN group 3',
                                     ' #comment3',
                                     ' ',
                                     ' + ##group3.1',
                                     ' | pattern7 @owner3',
                                     ' \\ ',
                                     ' + pattern71 @owner2',
                                     ' \\ ',
                                     ' + ##group3.2',
                                     ' | pattern8 @owner',
                                     ' | ',
                                     ' | pattern9 @owner',
                                     ' \\ ',
                                     ' # END group 3'
                                   ])
    end
  end

  describe '#owner' do
    it 'returns the first owner' do
      expect(group1.owner).to eq('@owner')
      expect(group3.owner).to eq('@owner')
      expect(group31.owner).to eq('@owner3')
    end
  end

  describe '#owners' do
    it 'returns owners ordered by the amount of occurences' do
      expect(group1.owners).to match_array(['@owner'])
      expect(group3.owners).to match_array(['@owner', '@owner2', '@owner3'])
    end
  end

  describe '#subgroups_owned_by' do
    context 'when subgroups owned by desired owner exist' do
      it 'returns array of subgroups owned by owner' do
        subgroups = subject.subgroups_owned_by('@owner')
        expect(subgroups.map(&:title)).to eq(['#group1', '#group2', '# BEGIN group 3'])
      end
    end

    context 'when no subgroup owned by desired owner exists' do
      it 'returns an ampty array' do
        subgroups = subject.subgroups_owned_by('@owner4')
        expect(subgroups.map(&:title)).to eq([])
      end
    end
  end

  describe '#title' do
    it 'returns the title of the group' do
      expect(group1.title).to eq('#group1')
      expect(group3.title).to eq('# BEGIN group 3')
      expect(no_name.title).to eq('pattern10 @owner2')
    end
  end

  describe '#add' do
    it 'adds new line to the group' do
      group1.add(pattern)
      expect(group1.to_content).to eq(
        ['#group1', 'pattern1 @owner', 'pattern2 @owner', 'pattern5 @owner',
         '', 'pattern4 @owner']
      )
    end
  end

  describe '#insert' do
    context 'when inserting in a group without a subgroup' do
      context 'in the middle of the group' do
        it 'inserts new pattern to the group in alphabetical order' do
          group1.insert(pattern)
          expect(group1.to_content).to eq(
            ['#group1', 'pattern1 @owner', 'pattern2 @owner',
             'pattern4 @owner', 'pattern5 @owner', '']
          )
        end
      end

      context 'when inserting in the first row after the initial comments' do
        it 'inserts new pattern to the first row' do
          group1.insert(pattern1)
          expect(group1.to_content).to eq(
            ['#group1', 'pattern @owner3', 'pattern1 @owner', 'pattern2 @owner',
             'pattern5 @owner', '']
          )
        end
      end

      context 'when inserting in the first row of a group with no comment' do
        it 'inserts the pattern in the first row' do
          no_name.insert(pattern1)
          expect(no_name.to_content).to eq(
            ['pattern @owner3', 'pattern10 @owner2', 'pattern11 @owner2', '']
          )
        end
      end
    end

    context 'when inserting in a group with a subgroup' do
      it 'inserts new pattern to the main group' do
        group3.insert(pattern)
        expect(group3.to_content).to eq(
          ['# BEGIN group 3', '#comment3', 'pattern4 @owner', '', '##group3.1',
           'pattern7 @owner3', '', 'pattern71 @owner2', '', '##group3.2', 'pattern8 @owner',
           '', 'pattern9 @owner', '', '# END group 3']
        )
      end
    end
  end

  describe '#remove' do
    let(:group4) { described_class.new }
    let(:comment) { Codeowners::Checker::Group::Line.build('#comment') }
    let(:unrecognized_line) { Codeowners::Checker::Group::Line.build('unrecognized_line') }
    let(:empty) { Codeowners::Checker::Group::Line.build('') }

    context 'when the group contains more than one patterns' do
      before do
        add_content(group4, '#Group4')
        group4.add(comment)
        group4.add(pattern)
        group4.add(unrecognized_line)
        add_content(group4, 'pattern5 @owner')
        group4.add(empty)
        subject.add(group4)
      end

      it 'removes pattern from the group' do
        group4.remove(pattern)
        expect(group4.to_content).to eq(
          ['#Group4', '#comment', 'unrecognized_line', 'pattern5 @owner', '']
        )
      end

      it 'removes comment from the group' do
        group4.remove(comment)
        expect(group4.to_content).to eq(
          ['#Group4', 'pattern4 @owner', 'unrecognized_line', 'pattern5 @owner', '']
        )
      end

      it 'removes empty line from the group' do
        group4.remove(empty)
        expect(group4.to_content).to eq(
          ['#Group4', '#comment', 'pattern4 @owner', 'unrecognized_line', 'pattern5 @owner']
        )
      end

      it 'removes unrecognized line from the group' do
        group4.remove(unrecognized_line)
        expect(group4.to_content).to eq(
          ['#Group4', '#comment', 'pattern4 @owner', 'pattern5 @owner', '']
        )
      end
    end

    context 'when there is only one pattern in the group' do
      let(:group41) { described_class.new }

      before do
        add_content(group4, '#Group4')
        group4.add(pattern)
        group4.add(empty)
        subject.add(group4)
        add_content(group41, '##Group4_1')
        group41.add(pattern1)
        group4.add(group41)
      end

      it 'removes the pattern, the title and the group from the parent group' do
        group41.remove(pattern1)
        expect(group41.to_content).to eq([])
        expect(group41.parent).to eq(nil)
        expect(group4.to_content).to eq(['#Group4', 'pattern4 @owner', ''])
      end
    end
  end
end
