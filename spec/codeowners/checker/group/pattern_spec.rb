# frozen_string_literal: true

require 'codeowners/checker/group/pattern'

RSpec.describe Codeowners::Checker::Group::Pattern do
  describe '#owner' do
    subject { described_class.build(line) }

    let(:line) { 'pattern @owner @owner1 @owner2' }

    it 'returns the first owner' do
      expect(subject.owner).to eq('@owner')
    end
  end

  describe '#match_file?' do
    subject { described_class.build(line) }

    {
      'directory/* @owner @owner2' => {
        'file.rb' => false,
        'directory/file.rb' => true,
        'directory/subdirectory/file.rb' => false
      },
      '* @owner' => {
        'file.rb' => true,
        'directory/file.rb' => true,
        'directory/subdirectory/file.rb' => true
      },
      'dir/dir1/* @owner' => {
        'file.rb' => false,
        'dir/file.rb' => false,
        'dir/dir1/file.rb' => true,
        'dir/dir1/dir2/file.rb' => false
      },
      'dir/dir1/file.rb @owner' => {
        'file.rb' => false,
        'dir/file.rb' => false,
        'dir/dir1/file.rb' => true,
        'dir/dir1/file1.rb' => false,
        'dir/dir1/dir2/file.rb' => false
      },
      '*.js @owner' => {
        'file.rb' => false,
        'dir/file.js' => true,
        'dir/dir1/file.rb' => false,
        'dir/dir1/file1.js' => true,
        'dir/dir1/dir2/file.js' => true
      }
    }.each do |content, tests|
      context "when the line is #{content.inspect}" do
        let(:line) { content }

        tests.each do |file, result|
          if result
            it { is_expected.to be_match_file(file) }
          else
            it { is_expected.not_to be_match_file(file) }
          end
        end
      end
    end
  end

  describe '#to_s' do
    subject { described_class.build(line) }

    context 'when one owner' do
      let(:line) { 'pattern @owner' }

      it 'converts pattern and owner to a string' do
        expect(subject.to_s).to eq('pattern @owner')
      end
    end

    context 'when multiple owners' do
      let(:line) { 'pattern @owner @owner1 @owner2' }

      it 'converts pattern and owner to a string' do
        expect(subject.to_s).to eq('pattern @owner @owner1 @owner2')
      end
    end
  end
end
