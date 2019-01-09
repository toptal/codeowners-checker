# frozen_string_literal: true

RSpec.describe Code::Ownership::CLI do
  subject(:cli) { described_class.new(args, options, config) }

  let(:args) { [] }
  let(:options) { {} }
  let(:config) { {} }

  after do
    File.delete(cli.default_team_file) if File.exist?(cli.default_team_file)
  end

  describe '#config' do
    it 'validates team file existence' do
      expect do
        cli.config
      end.to output(/Team name should be specified or a default team defined/).to_stdout
    end

    context 'when I have the file configured' do
      before do
        File.open(cli.default_team_file, 'w+') do |file|
          file.puts 'bootcamp'
        end
      end

      it 'shows the current team from file' do
        expect do
          cli.config
        end.to output("configured: @toptal/bootcamp\n").to_stdout
      end
    end

    context 'when config receives the team option argument' do
      let(:options) { { team: 'blacksmiths' } }

      it 'allow config a new team with the team parameter' do
        expect do
          cli.config
        end.to output("configured: @toptal/blacksmiths\n").to_stdout
      end
    end

    context 'when configured team is an invalid argument' do
      let(:options) { { team: nil } }

      it 'asks to provide a proper team name' do
        expect do
          cli.config
        end.to output(/Try `.* --team <team-name>` to configure the team/).to_stdout
      end
    end
  end
end
