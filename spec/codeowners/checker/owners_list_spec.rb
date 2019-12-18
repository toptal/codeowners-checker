# frozen_string_literal: true

require 'codeowners/checker/owners_list'

RSpec.describe Codeowners::Checker::OwnersList do
  subject(:owner_list) { described_class.new(folder_name) }

  let(:folder_name) { 'project' }

  ENV['GITHUB_TOKEN'] = nil
  ENV['GITHUB_ORGANIZATION'] = nil

  before do
    on_project_folder do
      File.open('OWNERS', 'w+') do |file|
        file.puts <<~CONTENT
          @owner
          @owner1
          @owner2
        CONTENT
      end
    end
  end

  def on_project_folder
    Dir.mkdir(folder_name) unless Dir.exist?(folder_name)
    Dir.chdir(folder_name) do
      yield
    end
  end

  after do
    FileUtils.rm_r(folder_name)
  end

  describe '#valid_owner?' do
    before do
      owner_list.owners
    end

    context 'when load OWNERS' do
      it 'validates owner from file' do
        expect(owner_list).to be_valid_owner('@owner1')
        expect(owner_list).not_to be_valid_owner('@unknown')
      end
    end

    context 'when skip owner validation' do
      before do
        owner_list.validate_owners = false
      end

      it 'returns true' do
        expect(owner_list).to be_valid_owner('@unknown')
      end
    end
  end

  describe '#persist!' do
    before do
      owner_list.owners = []
    end

    context 'when new user is added to owners_list' do
      before do
        owner_list.owners << '@new_owner'
        owner_list.persist!
      end

      it 'writes the user to OWNERS' do
        expect(File.read(subject.filename)).to eq("@new_owner\n")
      end
    end
  end

  describe '#<<' do
    it 'deduplicate owners' do
      owner_list.owners = []
      owner_list << '@new_owner'
      owner_list << '@new_owner'
      expect(owner_list.owners).to contain_exactly('@new_owner')
    end
  end
end
