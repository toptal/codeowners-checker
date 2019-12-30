# frozen_string_literal: true

require 'codeowners/checker/owners_list'

RSpec.describe Codeowners::Checker::OwnersList do
  subject(:owner_list) { described_class.new(folder_name, config) }

  let(:folder_name) { 'project' }
  let(:config) { instance_double('Codeowners::Config') }
  let(:env_token) { nil }
  let(:default_organization) { '' }

  around { |example| with_env('GITHUB_TOKEN' => env_token) { example.run } }

  before do
    allow(config).to receive(:default_organization).and_return(default_organization)
    on_dirpath(folder_name) { setup_owners_list('OWNERS') }
  end

  after do
    remove_dir(folder_name)
  end

  describe '#owners' do
    let(:retrieved_owners) { ['@owner'] }

    context 'with github credentials' do
      let(:env_token) { 'some-token' }
      let(:default_organization) { 'toptal' }

      before do
        allow(Codeowners::GithubFetcher).to receive(:get_owners).and_return(retrieved_owners)
      end

      it 'calls Codeowners::GithubFetcher.get_owners' do
        expect(Codeowners::GithubFetcher).to receive(:get_owners).with(default_organization, env_token)
        owner_list.owners
      end

      it 'returns the retrieved owners from github' do
        expect(owner_list.owners).to eq(retrieved_owners)
      end
    end

    context 'without github credentials' do
      let(:file_array) { instance_double('Codeowners::Checker::FileAsArray') }

      before do
        allow(Codeowners::Checker::FileAsArray).to receive(:new).and_return(file_array)
        allow(file_array).to receive(:content).and_return(retrieved_owners)
      end

      it 'calls Codeowners::Checker::FileAsArray.new.content' do
        expect(file_array).to receive(:content)
        owner_list.owners
      end

      it 'returns the retrieved owners from the file' do
        expect(owner_list.owners).to eq(retrieved_owners)
      end
    end
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

  describe '.persist!' do
    let(:owner_list) { instance_double(described_class.to_s) }
    let(:owners) { '@owner' }

    before do
      allow(described_class).to receive(:new).and_return(owner_list)
      allow(owner_list).to receive(:owners=).and_return(owners)
      allow(owner_list).to receive(:persist!).and_return(owners)
    end

    it 'initializes, adds owners and persists the changes' do
      expect(described_class).to receive(:new).with(folder_name, config)
      expect(owner_list).to receive(:owners=).with(owners)
      expect(owner_list).to receive(:persist!).with(no_args)
      described_class.persist!(folder_name, owners, config)
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
