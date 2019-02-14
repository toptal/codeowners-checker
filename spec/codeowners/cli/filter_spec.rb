# frozen_string_literal: true

require 'codeowners/cli/filter'

RSpec.describe Codeowners::Cli::Filter do
  subject(:cli) { described_class.new(args, options, config) }

  let(:args) { [] }
  let(:options) { {} }
  let(:git_config) { double }
  let(:checker) { double }
  let(:config) { { checker: checker, config: git_config } }

  before do
    allow(checker).to receive(:changes_with_ownership).and_return(diff)
  end

  describe '#by' do
    let(:diff) { { '@owner1' => ['lib/shared/file.rb'] } }

    context 'when filter by explicity owner' do
      let(:args) { %w[by @owner1] }

      it 'applies the user input as the filter' do
        expect(cli).not_to receive(:default_owner)
        expect do
          cli.by(args.last)
        end.to output(<<~OUTPUT).to_stdout
          lib/shared/file.rb
        OUTPUT
      end
    end

    context 'when do not pass any parameter' do
      let(:args) { %w[] }

      it 'applies `by` with `default_owner`' do
        expect(git_config).to receive(:default_owner).and_return('@owner1')
        cli.by
      end
    end

    context 'when the owner passed does not have any occurrence' do
      let(:args) { %w[] }

      it 'does not show any file' do
        expect do
          cli.by('@owner2')
        end.to output(<<~OUTPUT).to_stdout
          Owner @owner2 not defined in .github/CODEOWNERS
        OUTPUT
      end
    end
  end

  describe '#all' do
    let(:diff) do
      { '@owner1' => ['lib/shared/file.rb'],
        '@owner3' => ['lib/shared/other_file.rb'] }
    end

    context 'when files are changed' do
      it 'returns array containing owners changing files' do
        expect(cli.all).to match_array(['@owner1', '@owner3'])
      end

      it 'outputs string containing changed files and strings' do
        expect do
          cli.all
        end.to output(<<~OUTPUT).to_stdout
          @owner1:\n  lib/shared/file.rb\n
          @owner3:\n  lib/shared/other_file.rb\n
        OUTPUT
      end
    end

    context 'when no files are changed' do
      let(:diff) { {} }

      it 'returns an empty array' do
        expect(cli.all).to match_array([])
      end

      it 'outputs an empty string' do
        expect do
          cli.all
        end.to output('').to_stdout
      end
    end
  end
end
