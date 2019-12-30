# frozen_string_literal: true

require 'codeowners/checker'

RSpec.describe Codeowners::Checker do
  subject { described_class.new(folder_name, from, to).fix!.to_a }

  let(:folder_name) { 'project' }
  let(:from) { 'HEAD' }
  let(:to) { 'HEAD' }
  let(:git) { Git.open(folder_name, log: Logger.new(StringIO.new)) }

  def setup_project_folder
    on_dirpath(folder_name) do
      setup_code_owners
      setup_owners_list
      setup_billing_domain
      setup_shared_domain
      setup_gemfile
      setup_rubocop
    end
  end

  def setup_code_owners
    Dir.mkdir('.github')
    File.open('.github/CODEOWNERS', 'w+') do |file|
      file.puts <<~CONTENT
        # comment ignored
        .rubocop.yml @owner
        Gemfile @owner1
        lib/billing/* @owner2
        lib/shared/* @owner2 @owner1
      CONTENT
    end
  end

  def setup_billing_domain
    create_dir('lib/billing')
    File.open('lib/billing/file.rb', 'w+') do |file|
      file.puts <<~CONTENT
        # TODO: something not useful here
      CONTENT
    end
  end

  def setup_shared_domain
    create_dir('lib/shared')
    File.open('lib/shared/file.rb', 'w+') do |file|
      file.puts <<~CONTENT
        # TODO: some file that multiple owners share
      CONTENT
    end
  end

  def setup_gemfile
    File.open('Gemfile', 'w+') do |file|
      file.puts <<~CONTENT
        # frozen_string_literal: true
        source "https://rubygems.org"
        gem "granite"
      CONTENT
    end
  end

  def setup_rubocop
    File.open('.rubocop.yml', 'w+') do |file|
      file.puts <<~CONTENT
        Metrics/BlockLength:
          Path: spec/**
          Enabled: false

        Metrics/LineLength:
          Max: 120
      CONTENT
    end
  end

  def setup_git_for_project
    Git.init(folder_name)
    git.add(all: true)
    git.commit('First commit :yay:')
  end

  before do
    setup_project_folder
    setup_git_for_project
  end

  after do
    remove_dir(folder_name)
  end

  context 'without any changes it should not complain' do
    it { is_expected.to eq([]) }
  end

  context 'when introducing a new file in the git tree' do
    context 'when the file is not in the CODEOWNERS' do
      before do
        on_dirpath(folder_name) do
          filename = 'lib/new_file.rb'
          File.open(filename, 'w+') do |file|
            file.puts '# add some ruby code here'
          end
          git.add filename
          git.commit('New ruby file on lib')
        end
      end

      let(:from) { 'HEAD~1' }

      it 'fails if the file is not referenced in .github/CODEOWNERS' do
        expect(subject).to eq([[:missing_ref, 'lib/new_file.rb']])
      end
    end

    context 'when the files are not in the CODEOWNERS but generic patterns are' do
      before do
        on_dirpath(folder_name) do
          filename = 'lib/billing/new_file.rb'
          filename2 = 'app/file.js'
          Dir.mkdir('app')
          File.open(filename, 'w+') { |file| file.puts '# add some ruby code here' }
          File.open(filename2, 'w+') { |file| file.puts '# add some ruby code here' }
          File.open('.github/CODEOWNERS', 'a+') { |f| f.puts '**.js @owner3' }
          File.open('.github/OWNERS', 'a+') { |f| f.puts '@owner3' }

          git.add filename
          git.add filename2
          git.commit('New files')
        end
      end

      let(:from) { 'HEAD~1' }

      it 'does not list the files as missing reference' do
        expect(subject).to eq([])
      end
    end
  end

  context 'when unknown owner is added to CODEOWNERS' do
    before do
      on_dirpath(folder_name) do
        filename = 'lib/another_new_file.rb'
        File.open(filename, 'w+') { |file| file.puts '# add some ruby code here' }
        File.open('.github/CODEOWNERS', 'a+') { |f| f.puts "#{filename} @toptal/owner4 @owner5" }

        git.add filename
        git.commit('New files')
      end
    end

    it 'complains about invalid owner' do
      error_type, invalid_owner_checker = subject.first
      expect([error_type, invalid_owner_checker.owner]).to eq([:invalid_owner, '@toptal/owner4'])
    end

    context 'when no-validateowners is used' do
      subject { described_class.new folder_name, from, to }

      before do
        subject.owners_list.validate_owners = false
      end

      it 'does not complain' do
        expect(subject.fix!.to_a).to eq([])
      end
    end
  end

  context 'when removing a file from the git tree without updating CODEOWNERS' do
    before do
      on_dirpath(folder_name) do
        filename = '.rubocop.yml'
        File.delete(filename)
        git.add filename
        git.commit('Deleted file .rubocop.yml')
      end
    end

    it "fails if referencing lines aren't removed from .github/CODEOWNERS" do
      error_type, pattern_checker = subject.first
      expect([error_type, pattern_checker.pattern]).to eq([:useless_pattern, '.rubocop.yml'])
    end
  end

  context 'when removing a file from the git tree updating CODEOWNERS' do
    before do
      on_dirpath(folder_name) do
        filename = '.rubocop.yml'
        File.delete(filename)
        git.add filename

        # Update CODEOWNERS to remove reference...
        contents =
          File.readlines('.github/CODEOWNERS').reject do |line|
            line =~ /^\s*.rubocop.yml\s+/
          end

        File.open('.github/CODEOWNERS', 'w') do |f|
          contents.each do |line|
            f.write line
          end
        end

        git.add '.github/CODEOWNERS'
        git.commit('Remove .rubocop.yml and update code owners')
      end
    end

    it 'does not complain' do
      expect(subject).to eq([])
    end
  end

  context 'when adding unrecognized line' do
    before do
      on_dirpath(folder_name) do
        filename = 'lib/shared/random.rb'
        File.open(filename, 'w+') { |file| file.puts '# add some ruby code here' }
        File.open('.github/CODEOWNERS', 'a+') { |f| f.puts filename }

        git.add filename
        git.commit('New files')
      end
    end

    it 'complains about unrecognized line' do
      error_type, unrecognized_line_check = subject.first
      expect([error_type, unrecognized_line_check.to_s]).to eq([:unrecognized_line, 'lib/shared/random.rb'])
    end
  end

  describe '.patterns_by_owner' do
    subject { described_class.new folder_name, from, to }

    it 'collets patterns grouped by owner' do
      expect(subject.patterns_by_owner)
        .to eq(
          '@owner' => ['.rubocop.yml'],
          '@owner2' => ['lib/billing/*', 'lib/shared/*'],
          '@owner1' => ['Gemfile', 'lib/shared/*']
        )
    end
  end

  describe '.changes_with_ownership' do
    subject { described_class.new folder_name, from, to }

    it 'collets changes from a specific owner' do
      expect(subject.changes_with_ownership)
        .to eq('@owner' => [], '@owner2' => [], '@owner1' => [])
    end

    context 'when passing a specific owner' do
      it do
        expect(subject.changes_with_ownership('owner')).to be_empty
      end
    end

    context 'when changing files from a specific owner' do
      let(:from) { 'HEAD~1' }

      before do
        on_dirpath(folder_name) do
          filename = '.rubocop.yml'
          File.open(filename, 'a+') { |f| f.puts '# useless line' }
          git.add filename
          git.commit('Updated .rubocop.yml with useless content')
        end
      end

      it do
        expect(subject.changes_with_ownership('@owner')).to eq('@owner' => ['.rubocop.yml'])
      end
    end

    context 'when changing files from multiple owners' do
      let(:from) { 'HEAD~1' }

      before do
        on_dirpath(folder_name) do
          filename = 'lib/shared/file.rb'
          File.open(filename, 'a+') { |f| f.puts '# useless line' }
          git.add filename
          git.commit('Updated shared file')
        end
      end

      specify do
        changes_from = subject.method(:changes_with_ownership)
        expect(changes_from['@owner']).to eq('@owner' => [])
        expect(changes_from['@owner1']).to eq('@owner1' => ['lib/shared/file.rb'])
        expect(changes_from['@owner2']).to eq('@owner2' => ['lib/shared/file.rb'])
      end
    end
  end

  describe '#codeowners' do
    subject { described_class.new(folder_name, from, to) }

    context 'when the file is in the .github folder' do
      it 'returns the content of the codeowners file' do
        expect(subject.codeowners).to be_a(Codeowners::Checker::CodeOwners)
        expect(subject.codeowners.to_content).to eq(
          ['# comment ignored', '.rubocop.yml @owner', 'Gemfile @owner1', 'lib/billing/* @owner2',
           'lib/shared/* @owner2 @owner1']
        )
      end
    end

    context 'when the file is in the root folder' do
      before { move_dir('project/.github/CODEOWNERS', 'project/CODEOWNERS') }

      it 'returns the content of the codeowners file' do
        expect(subject.codeowners.to_content).to eq(
          ['# comment ignored', '.rubocop.yml @owner', 'Gemfile @owner1', 'lib/billing/* @owner2',
           'lib/shared/* @owner2 @owner1']
        )
      end
    end

    context 'when the file does not exist' do
      before { remove_file('project/.github/CODEOWNERS') }

      it 'uses a root folder for the file and returns an empty array for the content' do
        expect(subject.codeowners.to_content).to eq([])
      end
    end
  end

  describe '#main_group' do
    subject { described_class.new(folder_name, from, to) }

    it 'returns an array containing the main group' do
      expect(subject.main_group.to_content).to eq(
        ['# comment ignored', '.rubocop.yml @owner', 'Gemfile @owner1', 'lib/billing/* @owner2',
         'lib/shared/* @owner2 @owner1']
      )
      expect(subject.main_group).to be_a(Codeowners::Checker::Group)
    end
  end
end
