# frozen_string_literal: true

require 'code/ownership/checker/group'

RSpec.describe Code::Ownership::Checker::Group do
  subject { described_class.new }

  let(:comments_group) { described_class.new }
  let(:group1) { described_class.new }
  let(:no_name) { described_class.new }
  let(:group2) { described_class.new }
  let(:group3) { described_class.new }
  let(:pattern) { Code::Ownership::Checker::Group::Line.build('pattern5 @owner') }
  let(:pattern1) { Code::Ownership::Checker::Group::Line.build('pattern @owner3') }

  def add_content(group, text)
    group.add(Code::Ownership::Checker::Group::Line.build(text))
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
    add_content(group1, 'pattern3 @owner')
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
    group3_1 = described_class.new
    add_content(group3_1, '##group3.1')
    add_content(group3_1, 'pattern7 @owner3')
    add_content(group3_1, '')
    group3.add(group3_1)
    group3_no_name = described_class.new
    add_content(group3_no_name, 'pattern71 @owner2')
    add_content(group3_no_name, '')
    group3.add(group3_no_name)
    group3_2 = described_class.new
    add_content(group3_2, '##group3.2')
    add_content(group3_2, 'pattern8 @owner')
    add_content(group3_2, '')
    add_content(group3_2, 'pattern9 @owner')
    add_content(group3_2, '')
    group3.add(group3_2)
    add_content(group3, '# END group 3')
    subject.add(group3)
  end

  describe '#owner' do
    it 'returns the first owner' do
      expect(group1.owner).to eq('@owner')
      expect(group3.owner).to eq('@owner3')
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
        expect(subgroups.map(&:title)).to eq(['#group1', '#group2'])
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
        ['#group1', 'pattern1 @owner', 'pattern2 @owner', 'pattern3 @owner',
         '', 'pattern5 @owner']
      )
    end
  end

  describe '#insert' do
    context 'when inserting in a group without a subgroup' do
      it 'inserts new pattern to the group in alphabetical order' do
        group1.insert(pattern)
        expect(group1.to_content).to eq(
          ['#group1', 'pattern1 @owner', 'pattern2 @owner',
           'pattern3 @owner', 'pattern5 @owner', '']
        )
      end
    end

    context 'when inserting in a first row of a group' do
      it 'inserts the pattern in the first row' do
        no_name.insert(pattern1)
        expect(no_name.to_content).to eq(
          ['pattern @owner3', 'pattern10 @owner2', 'pattern11 @owner2', '']
        )
      end
    end

    context 'when inserting in a group with a subgroup' do
      it 'inserts new pattern to the main group' do
        group3.insert(pattern)
        expect(group3.to_content).to eq(
          ['# BEGIN group 3', '#comment3', 'pattern5 @owner', '', '##group3.1',
           'pattern7 @owner3', '', 'pattern71 @owner2', '', '##group3.2', 'pattern8 @owner',
           '', 'pattern9 @owner', '', '# END group 3']
        )
      end
    end
  end

  describe '#remove' do
    context 'when group contains other patterns' do
      before { group1.insert(pattern) }

      it 'removes the pattern from the group' do
        group1.remove(pattern)
        expect(group1.to_content).to eq(
          ['#group1', 'pattern1 @owner', 'pattern2 @owner', 'pattern3 @owner', '']
        )
      end
    end

    context 'when there is only one pattern in the group' do
      let(:group4) { described_class.new }

      before do
        add_content(group4, '#Group4')
        group4.add(pattern)
        subject.add(group4)
      end

      it 'removes the pattern and the title of the group' do
        group4.remove(pattern)
        expect(group4.to_content).to eq([])
      end
    end
  end
end
