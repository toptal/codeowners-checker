# frozen_string_literal: true

require 'code/ownership/cli/filter'

RSpec.describe Code::Ownership::Cli::Filter do
  subject(:cli) { described_class.new(args, options, config) }

  let(:args) { [] }
  let(:options) { {} }
  let(:git_config) { double }
  let(:config) { { config: git_config } }

  describe '#by' do
    let(:diff) { { '@toptal/bootcamp' => ['lib/shared/file.rb'] } }

    let(:checker) do
      checker = double
      allow(checker).to receive(:changes_with_ownership).and_return(diff)
      checker
    end

    let(:config) { { checker: checker, config: git_config } }

    context 'when filter by explicity owner' do
      let(:args) { %w[by @toptal/bootcamp] }

      it 'applies the user input as the filter' do
        expect(cli).not_to receive(:default_team)
        expect do
          cli.by(args.last)
        end.to output(<<~OUTPUT).to_stdout
          lib/shared/file.rb
        OUTPUT
      end
    end

    context 'when do not pass any parameter' do
      let(:args) { %w[] }

      it 'applies `by` with `default_team`' do
        expect(git_config).to receive(:default_team).and_return('@toptal/bootcamp')
        cli.by
      end
    end

    context 'when the team passed does not have any occurrence' do
      let(:args) { %w[] }

      it 'does not show any file' do
        expect do
          cli.by('@toptal/other')
        end.to output(<<~OUTPUT).to_stdout
          Owner @toptal/other not defined in .github/CODEOWNERS
        OUTPUT
      end
    end
  end
end
