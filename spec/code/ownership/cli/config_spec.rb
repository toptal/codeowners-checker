# frozen_string_literal: true

require 'code/ownership/cli/config'

RSpec.describe Code::Ownership::Cli::Config do
  subject(:cli) { described_class.new(args, options, config) }

  let(:args) { [] }
  let(:options) { {} }
  let(:git_config) { Code::Ownership::Config.new(fake_git) }
  let(:fake_git) { double }
  let(:config) { { config: git_config } }

  describe '#list' do
    it 'fetch the owner from git config and show it' do
      expect(cli).not_to receive(:help)
      expect(git_config).to receive(:default_owner).and_return('@owner1').twice
      expect do
        cli.list
      end.to output("default_owner: \"@owner1\"\n").to_stdout
    end

    it 'asks to provide a proper owner name' do
      expect(cli).to receive(:help)
      expect(git_config).to receive(:default_owner).and_return('').twice
      expect do
        cli.list
      end.to output("default_owner: \"\"\n").to_stdout
    end
  end

  describe '#owner' do
    it 'config the owner in the git config file' do
      expect(git_config).to receive(:default_owner=).with('@owner1')
      expect do
        cli.owner('@owner1')
      end.to output("Default owner configured to @owner1\n").to_stdout
    end
  end
end
