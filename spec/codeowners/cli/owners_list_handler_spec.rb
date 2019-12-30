# frozen_string_literal: true

require 'codeowners/cli/owners_list_handler'

RSpec.describe Codeowners::Cli::OwnersListHandler do
  subject(:cli) { described_class.new(args, options, config) }

  let(:args) { [] }
  let(:options) { {} }
  let(:config) { { config: git_config } }
  let(:git_config) { Codeowners::Config.new(fake_git) }
  let(:fake_git) { instance_double('Git') }
  let(:owners_list) { instance_double('String') }
  let(:repo) { '.' }
  let(:fetch) { cli.fetch(repo) }
  let(:default_organization) { '' }

  before do
    allow(git_config).to receive(:default_organization).and_return(default_organization)
  end

  describe '#fetch' do
    before do
      ENV['GITHUB_TOKEN'] = env_token
      allow(Codeowners::GithubFetcher).to receive(:get_owners).and_return(owners_list)
      allow(Codeowners::Checker::OwnersList).to receive(:persist!).and_return(owners_list)
    end

    let(:output_message) { described_class::FETCH_OWNER_MESSAGE + "\n" }

    context 'with organization and token from ENV' do
      let(:default_organization) { 'toptal' }
      let(:env_token) { 'xxxsecretxxx' }

      it 'fetchs the owners from github' do
        expect(Codeowners::GithubFetcher).to receive(:get_owners).with(default_organization, env_token)
        fetch
      end

      it 'outputs progress message to stdout' do
        expect { fetch }.to output(output_message).to_stdout
      end

      it 'persists owners' do
        expect(Codeowners::Checker::OwnersList).to receive(:persist!).with(repo, owners_list).and_return(owners_list)
        fetch
      end
    end

    context 'without organization' do
      let(:env_token) { 'xxxsecretxxx' }
      let(:asked_message) { described_class::ASK_GITHUB_ORGANIZATION + ' ' }
      let(:asked_organization) { 'toptal' }

      before do
        allow(Thor::LineEditor).to receive(:readline).with(asked_message, {}).and_return(asked_organization)
      end

      it 'asks for an organization' do
        expect(Thor::LineEditor).to receive(:readline).with(asked_message, {})
        fetch
      end

      it 'fetchs the owners from github' do
        expect(Codeowners::GithubFetcher).to receive(:get_owners).with(asked_organization, env_token)
        fetch
      end

      it 'outputs progress message to stdout' do
        expect { fetch }.to output(output_message).to_stdout
      end

      it 'persists owners' do
        expect(Codeowners::Checker::OwnersList).to receive(:persist!).with(repo, owners_list).and_return(owners_list)
        fetch
      end
    end

    context 'without token' do
      let(:default_organization) { 'toptal' }
      let(:env_token) { nil }
      let(:asked_message) { described_class::ASK_GITHUB_TOKEN + ' ' }
      let(:asked_token) { 'xxxsecretxxx' }

      before do
        allow(Thor::LineEditor).to receive(:readline).with(asked_message, echo: false).and_return(asked_token)
      end

      it 'asks for a token' do
        expect(Thor::LineEditor).to receive(:readline).with(asked_message, echo: false)
        fetch
      end

      it 'fetchs the owners from github' do
        expect(Codeowners::GithubFetcher).to receive(:get_owners).with(default_organization, asked_token)
        fetch
      end

      it 'outputs progress message to stdout' do
        expect { fetch }.to output(output_message).to_stdout
      end

      it 'persists owners' do
        expect(Codeowners::Checker::OwnersList).to receive(:persist!).with(repo, owners_list).and_return(owners_list)
        fetch
      end
    end
  end
end
