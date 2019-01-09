# frozen_string_literal: true

require 'fileutils'

RSpec.describe Code::Ownership::Checker do
  subject { described_class.check! folder_name, from, to }

  let(:folder_name) { 'project' }
  let(:from) { 'HEAD' }
  let(:to) { 'HEAD' }
  let(:git) { Git.open(folder_name, log: Logger.new(STDOUT)) }

  def setup_project_folder
    on_project_folder do
      setup_code_owners
      setup_billing_domain
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
        .rubocop.yml @jonatas
        Gemfile @toptal/rogue-one
        lib/billing/* @toptal/billing
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
          '@jonatas' => ['.rubocop.yml'],
          '@toptal/billing' => ['lib/billing/*'],
          '@toptal/rogue-one' => ['Gemfile']
        )
    end
  end

  describe '.changes_with_ownership' do
    subject { described_class.new folder_name, from, to }

    it 'collets changes from a specific team' do
      expect(subject.changes_with_ownership)
        .to eq('@jonatas' => [], '@toptal/billing' => [], '@toptal/rogue-one' => [])
    end
    context 'when passing a specific owner' do
      it do
        expect(subject.changes_with_ownership('jonatas')).to be_empty
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
        expect(subject.changes_with_ownership('@jonatas')).to eq('@jonatas' => ['.rubocop.yml'])
      end
    end
  end
end
