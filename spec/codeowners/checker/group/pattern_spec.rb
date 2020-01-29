# frozen_string_literal: true

# Pattern specification described by gitscm
# https://git-scm.com/docs/gitignore

require 'codeowners/checker/group/pattern'

RSpec.describe Codeowners::Checker::Group::Pattern do
  subject(:pattern) { described_class.build(line) }

  describe '#owner' do
    let(:line) { 'pattern @owner @owner1 @owner2' }

    it 'returns the first owner' do
      expect(pattern.owner).to eq('@owner')
    end
  end

  describe '#match_file?' do
    # An asterisk "*" matches anything except a slash. The character "?"
    # matches any one character except "/". The range notation, e.g. [a-zA-Z],
    # can be used to match one of the characters in a range.
    # See fnmatch(3) and the FNM_PATHNAME flag for a more detailed description.

    context 'with a single asterix' do
      let(:line) { '* @owner' }

      it { is_expected.to be_match_file('.file.rb') }
      it { is_expected.to be_match_file('dir/.file.rb') }
      it { is_expected.to be_match_file('dir/subdir/file.rb') }
    end

    context 'with dir/* @owner @owner2' do
      let(:line) { 'dir/* @owner @owner2' }

      it { is_expected.to be_match_file('dir/file.rb') }
      it { is_expected.not_to be_match_file('file.rb') }
      it { is_expected.not_to be_match_file('dir/subdir/file.rb') }
    end

    context 'with dir/*/file.rb @owner' do
      let(:line) { 'dir/*/file.rb @owner' }

      it { is_expected.to be_match_file('dir/subdir/file.rb') }
      it { is_expected.not_to be_match_file('file.rb') }
      it { is_expected.not_to be_match_file('dir/file.rb') }
      it { is_expected.not_to be_match_file('dir/subdir/after/file.rb') }
    end

    context 'with /dir/subdir/*file* @owner' do
      let(:line) { '/dir/subdir/*file* @owner' }

      it { is_expected.to be_match_file('dir/subdir/file.rb') }
      it { is_expected.to be_match_file('dir/subdir/other_file.rb') }
      it { is_expected.not_to be_match_file('dir/file.rb') }
      it { is_expected.not_to be_match_file('before/dir/subdir/other_file.rb') }
      it { is_expected.not_to be_match_file('dir/subdir/after/file.rb') }
    end

    context 'with *.js @owner' do
      let(:line) { '*.js @owner' }

      it { is_expected.to be_match_file('file.js') }
      it { is_expected.to be_match_file('dir/file.js') }
      it { is_expected.to be_match_file('dir/subdir/other_file.js') }
      it { is_expected.to be_match_file('dir/subdir/after/file.js') }
      it { is_expected.not_to be_match_file('file.rb') }
      it { is_expected.not_to be_match_file('dir/subdir/file.rb') }
    end

    context 'with ?ile[a-z1-9].rb @owner' do
      let(:line) { '?ile[a-z1-9].rb @owner' }

      it { is_expected.to be_match_file('file1.rb') }
      it { is_expected.not_to be_match_file('file.rb') }
      it { is_expected.not_to be_match_file('file-a.rb') }
      it { is_expected.not_to be_match_file('other_file1.rb') }
    end

    context 'with dir/** @owner' do
      let(:line) { 'dir/** @owner' }

      it { is_expected.not_to be_match_file('file.rb') }
      it { is_expected.to be_match_file('dir/file.rb') }
      it { is_expected.to be_match_file('dir/subdir/file.rb') }
      it { is_expected.to be_match_file('dir/subdir/after/file.rb') }
    end

    # Two consecutive asterisks ("**") in patterns matched against full
    # pathname may have special meaning:

    # A leading "**" followed by a slash means match in all directories.
    # For example, "**/foo" matches file or directory "foo" anywhere, the
    # same as pattern "foo". "**/foo/bar" matches file or directory "bar"
    # anywhere that is directly under directory "foo".

    context 'with **/dir/file.rb @owner' do
      let(:line) { '**/dir/file.rb @owner' }

      it { is_expected.to be_match_file('dir/file.rb') }
      it { is_expected.to be_match_file('before/dir/file.rb') }
      it { is_expected.to be_match_file('root/before/dir/file.rb') }
      it { is_expected.not_to be_match_file('file.rb') }
    end

    context 'with **.js @owner' do
      let(:line) { '**.js @owner' }

      it { is_expected.to be_match_file('dir/file.js') }
      it { is_expected.to be_match_file('dir/subdir/other_file.js') }
      it { is_expected.to be_match_file('dir/subdir/after/file.js') }
      it { is_expected.not_to be_match_file('file.rb') }
      it { is_expected.not_to be_match_file('dir/subdir/file.rb') }
    end

    context 'with ** @owner' do
      let(:line) { '** @owner' }

      it { is_expected.to be_match_file('.file.rb') }
      it { is_expected.to be_match_file('directory/.file.rb') }
      it { is_expected.to be_match_file('directory/subdirectory/file.rb') }
    end

    # A trailing "/**" matches everything inside. For example, "abc/**"
    # matches all files inside directory "abc", relative to the location
    # of the .gitignore file, with infinite depth.

    context 'with dir/** @owner' do
      let(:line) { 'dir/** @owner' }

      it { is_expected.to be_match_file('dir/file.rb') }
      it { is_expected.to be_match_file('dir/subdir/file.js') }
      it { is_expected.not_to be_match_file('file.rb') }
      it { is_expected.not_to be_match_file('oher/file.rb') }
    end

    # A slash followed by two consecutive asterisks then a slash matches
    # zero or more directories.
    # For example, "a/**/b" matches "a/b", "a/x/b", "a/x/y/b" and so on.

    context 'with dir/**/file.rb @owner' do
      let(:line) { 'dir/**/file.rb @owner' }

      it { is_expected.to be_match_file('dir/file.rb') }
      it { is_expected.to be_match_file('dir/subdir/file.rb') }
      it { is_expected.to be_match_file('dir/subdir/after/file.rb') }
    end

    context 'with dir @owner' do
      let(:line) { 'dir @owner' }

      it { is_expected.to be_match_file('dir/file.rb') }
      it { is_expected.to be_match_file('dir/real_sub/file.rb') }
      it { is_expected.not_to be_match_file('file.rb') }
    end

    context 'with dir/ @owner' do
      let(:line) { 'dir/ @owner' }

      it { is_expected.to be_match_file('dir/file.rb') }
      it { is_expected.to be_match_file('dir/subdir/file.rb') }
      it { is_expected.not_to be_match_file('file.rb') }
    end
  end

  describe '#pattern=' do
    context 'when have whitespaces' do
      let(:line) { 'pattern      @owner' }

      it 'recalculates whitespaces to keep the same identation' do
        expect do
          pattern.pattern = 'pattern2'
        end.to change(subject, :whitespace).from(5).to(4)
      end

      it 'keep one whitespaces case the new pattern does not fit' do
        expect do
          pattern.pattern = 'pattern23456789'
        end.to change(pattern, :whitespace).from(5).to(1)
      end

      it { expect(pattern.spec).not_to be_empty }
    end
  end

  describe '#rename_owner' do
    let(:line) { 'pattern @owner' }

    it 'changes owner' do
      expect { pattern.rename_owner('@owner', '@new_owner') }
        .to change(pattern, :owner).to('@new_owner')
    end

    it 'prevents duplicates' do
      pattern.rename_owner('@owner', '@owner')
      expect(pattern.owners).to contain_exactly('@owner')
    end
  end

  describe '#to_file' do
    context 'when one owner' do
      let(:line) { 'pattern @owner' }

      it 'converts pattern and owner to a string' do
        expect(pattern.to_s).to eq('pattern @owner')
      end
    end

    context 'when multiple owners' do
      let(:line) { 'pattern @owner @owner1 @owner2' }

      it 'converts pattern and owner to a string' do
        expect(pattern.to_s).to eq('pattern @owner @owner1 @owner2')
      end
    end

    context 'when the line have whitespaces' do
      let(:line) { 'pattern          @owner' }

      it 'keeps the white spaces' do
        expect(pattern.to_file).to eq(line)
      end

      context 'without preserve white spaces option' do
        it 'keeps the white spaces' do
          expect(pattern.to_file(preserve_whitespaces: false)).to eq('pattern @owner')
        end
      end
    end
  end
end
