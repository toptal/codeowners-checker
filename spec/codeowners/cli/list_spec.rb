# frozen_string_literal: true

require 'codeowners/cli/filter'

RSpec.describe Codeowners::Cli::List do
  subject(:cli) { described_class.new(args, options, config) }

  let(:args) { [] }
  let(:options) { {} }
  let(:git_config) { double }
  let(:checker) { double }
  let(:config) { { checker: checker, config: git_config } }

  before do
    allow(checker).to receive(:list_files_for_owner).and_return(results)
  end

  describe '#by' do
    let(:results) do
      { 'foo/**/*.rb' => ['foo/bar.rb', 'foo/baz.rb'],
        'bar/**/*.rb' => ['bar/foo.rb', 'bar/baz.rb'] }
    end

    context 'when filter by explicity owner' do
      let(:args) { %w[by @owner1] }

      it 'applies the user input as the filter' do
        expect(cli).not_to receive(:default_owner)
        expect do
          cli.by(args.last)
        end.to output(<<~OUTPUT).to_stdout
          Checking ownership for '@owner1'
          Pattern: 'foo/**/*.rb' - matches 2 file(s)
          Pattern: 'bar/**/*.rb' - matches 2 file(s)
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
  end
end
