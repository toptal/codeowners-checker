# frozen_string_literal: true

RSpec.describe Code::Ownership::Filter do
  subject(:cli) { described_class.new(args, options, config) }

  let(:args) { [] }
  let(:options) { {} }
  let(:config) { {} }

  describe '#default_team' do
    context 'when I have the file configured' do
      before do
        File.open(cli.default_team_file, 'w+') do |file|
          file.puts '@toptal/bootcamp'
        end
      end

      after do
        File.delete(cli.default_team_file) if File.exist?(cli.default_team_file)
      end

      it 'uses the config file to restore the team name' do
        expect(cli.default_team).to eq('@toptal/bootcamp')
      end
    end

    context 'when the config file does not exist' do
      it 'returns nil' do
        expect(cli.default_team).to be_nil
      end
    end
  end

  describe '#by' do
    let(:diff) { { '@toptal/bootcamp' => ['lib/shared/file.rb'] } }

    let(:checker) do
      checker = double
      allow(checker).to receive(:changes_with_ownership).and_return(diff)
      checker
    end

    let(:config) { { checker: checker } }

    context 'when filter by explicity owner' do
      let(:args) { %w[by @toptal/bootcamp] }

      it 'applies the user input as the filter' do
        expect(cli).not_to have_received(:default_team)
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
        expect(cli).to receive(:default_team).and_return('@toptal/bootcamp')
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
