# frozen_string_literal: true

require 'fileutils'
require 'codeowners/checker'

RSpec.describe Codeowners::Checker do
  subject { described_class.check! folder_name, from, to }

  let(:folder_name) { 'project' }
  let(:from) { 'HEAD' }
  let(:to) { 'HEAD' }
  let(:git) { Git.open(folder_name, log: Logger.new(STDOUT)) }

  def setup_project_folder
    on_project_folder do
      setup_code_owners
      setup_billing_domain
      setup_shared_domain
      setup_gemfile
      setup_rubocop
    end
  end

  def on_project_folder
    Dir.mkdir(folder_name) unless Dir.exist?(folder_name)
    Dir.chdir(folder_name) do
      yield
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
    FileUtils.mkdir_p('lib/billing')
    File.open('lib/billing/file.rb', 'w+') do |file|
      file.puts <<~CONTENT
        # TODO: something not useful here
      CONTENT
    end
  end

  def setup_shared_domain
    FileUtils.mkdir_p('lib/shared')
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
    FileUtils.rm_r(folder_name)
  end

  context 'without any changes it should not complain' do
    it { is_expected.to eq(missing_ref: [], useless_pattern: []) }
  end

  context 'when introducing a new file in the git tree' do
    before do
      on_project_folder do
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
      expect(subject).to eq(missing_ref: ['lib/new_file.rb'], useless_pattern: [])
    end
  end

  context 'when removing a file from the git tree without updating CODEOWNERS' do
    before do
      on_project_folder do
        filename = '.rubocop.yml'
        File.delete(filename)
        git.add filename
        git.commit('Deleted file .rubocop.yml')
      end
    end

    it "fails if referencing lines aren't removed from .github/CODEOWNERS" do
      expect(subject[:useless_pattern].first.pattern).to eq('.rubocop.yml')
    end
  end

  context 'when removing a file from the git tree updating CODEOWNERS' do
    before do
      on_project_folder do
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
      expect(subject).to eq(missing_ref: [], useless_pattern: [])
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
        on_project_folder do
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
        on_project_folder do
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
end
