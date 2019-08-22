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
      '/dir/dir1/*file* @owner' => {
        'dir/file.rb' => false,
        'dir/dir1/file.rb' => true,
        'dir/dir1/other_file.rb' => true,
        'other/dir/dir1/other_file.rb' => false,
        'dir/dir1/dir2/file.rb' => false
      },
      'dir/*/file.rb @owner' => {
        'file.rb' => false,
        'dir/file.rb' => false,
        'dir/dir1/file.rb' => true,
        'dir/dir1/dir2/file.rb' => false
      },
      'dir/** @owner' => {
        'file.rb' => false,
        'dir/file.rb' => true,
        'dir/dir1/file.rb' => true,
        'dir/dir1/dir2/file.rb' => true
      },
      'dir/**/file.rb @owner' => {
        'dir/file.rb' => false,
        'dir/dir1/file.rb' => true,
        'dir/dir1/dir2/file.rb' => true
      },
      '?ile[a-z1-9].rb @owner' => {
        'file.rb' => false,
        'file1.rb' => true,
        'file-a.rb' => false,
        'other_file1.rb' => false
      },
      '**/dir/file.rb @owner' => {
        'file.rb' => false,
        'dir/file.rb' => false,
        'dir1/dir/file.rb' => true,
        'dir1/dir2/dir/file.rb' => true
      },
      '*.js @owner' => {
        'file.rb' => false,
        'file.js' => true,
        'another_file.js' => true,
        'dir/file.js' => false,
        'dir/dir1/file.rb' => false,
        'dir/dir1/file1.js' => false,
        'dir/dir1/dir2/file.js' => false
      },
      '**.js @owner' => {
        'file.rb' => false,
        'dir/file.js' => true,
        'dir/dir1/file.rb' => false,
        'dir/dir1/file1.js' => true,
        'dir/dir1/dir2/file.js' => true
      },
      '* @owner' => {
        '.file.rb' => true,
        'directory/.file.rb' => false,
        'directory/subdirectory/file.rb' => false
      },
      '** @owner' => {
        '.file.rb' => true,
        'directory/.file.rb' => true,
        'directory/subdirectory/file.rb' => true
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

  describe '#pattern=' do
    subject { described_class.build(line) }

    context 'when have whitespaces' do
      let(:line) { 'pattern      @owner' }

      it 'recalculates whitespaces to keep the same identation' do
        expect do
          subject.pattern = 'pattern2'
        end.to change(subject, :whitespace).from(5).to(4)
      end

      it 'keep one whitespaces case the new pattern does not fit' do
        expect do
          subject.pattern = 'pattern23456789'
        end.to change(subject, :whitespace).from(5).to(1)
      end
    end
  end

  describe '#to_file' do
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

    context 'when the line have whitespaces' do
      let(:line) { 'pattern          @owner' }

      it 'keeps the white spaces' do
        expect(subject.to_file).to eq(line)
      end

      context 'without preserve white spaces option' do
        it 'keeps the white spaces' do
          expect(subject.to_file(preserve_whitespaces: false)).to eq('pattern @owner')
        end
      end
    end
  end
end
