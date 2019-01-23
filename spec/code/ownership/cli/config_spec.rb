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
    it 'fetch the team from git config and show it' do
      expect(cli).not_to receive(:help)
      expect(git_config).to receive(:default_team).and_return('@toptal/bootcamp').twice
      expect do
        cli.list
      end.to output("default_team: \"@toptal/bootcamp\"\n").to_stdout
    end

    it 'asks to provide a proper team name' do
      expect(cli).to receive(:help)
      expect(git_config).to receive(:default_team).and_return('').twice
      expect do
        cli.list
      end.to output("default_team: \"\"\n").to_stdout
    end
  end

  describe '#team' do
    it 'config the team in the git config file' do
      expect(git_config).to receive(:default_team=).with('@toptal/bootcamp')
      expect do
        cli.team('@toptal/bootcamp')
      end.to output("Default team configured to @toptal/bootcamp\n").to_stdout
    end
  end
end
