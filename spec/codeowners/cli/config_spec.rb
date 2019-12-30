# frozen_string_literal: true

require 'codeowners/cli/config'

RSpec.describe Codeowners::Cli::Config do
  subject(:cli) { described_class.new(args, options, config) }

  let(:args) { [] }
  let(:options) { {} }
  let(:git_config) { Codeowners::Config.new(fake_git) }
  let(:fake_git) { double }
  let(:config) { { config: git_config } }

  describe '#list' do
    before do
      allow(git_config).to receive(:default_owner).and_return(default_owner)
      allow(git_config).to receive(:default_organization).and_return(default_organization)
    end

    let(:default_owner) { '@owner1' }
    let(:default_organization) { 'toptal' }

    context 'with owner and organization' do
      it 'fetches the owner from git config and shows it' do
        expect { cli.list }.to output(/default_owner: "@owner1"\n/).to_stdout
      end

      it 'fetches the organization from git config and shows it' do
        expect { cli.list }.to output(/default_organization: "toptal"\n/).to_stdout
      end

      it 'does not print help' do
        expect(cli).not_to receive(:help)
        cli.list
      end
    end

    context 'without owner name' do
      let(:default_owner) { '' }

      it 'prints help' do
        expect(cli).to receive(:help)
        cli.list
      end

      it 'shows empty owner' do
        expect { cli.list }.to output(/default_owner: ""\n/).to_stdout
      end
    end

    context 'without organization name' do
      let(:default_organization) { '' }

      it 'prints help' do
        expect(cli).to receive(:help)
        cli.list
      end

      it 'shows empty organization' do
        expect { cli.list }.to output(/default_organization: ""\n/).to_stdout
      end
    end
  end

  describe '#owner' do
    let(:new_owner) { '@owner1' }

    before do
      allow(git_config).to receive(:default_owner=)
    end

    it 'changes the owner in the git config file' do
      expect(git_config).to receive(:default_owner=).with(new_owner)
      cli.owner(new_owner)
    end

    it 'outputs success message' do
      expect do
        cli.owner(new_owner)
      end.to output("Default owner configured to @owner1\n").to_stdout
    end
  end

  describe '#organization' do
    let(:new_org) { '@new-org' }

    it 'changes the organization in the git config file' do
      expect(git_config).to receive(:default_organization=).with(new_org)
      cli.organization(new_org)
    end

    it 'outputs success message' do
      allow(git_config).to receive(:default_organization=)
      expect do
        cli.organization(new_org)
      end.to output("Default organization configured to @new-org\n").to_stdout
    end
  end
end
