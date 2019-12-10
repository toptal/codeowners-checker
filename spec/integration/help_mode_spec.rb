# frozen_string_literal: true

RSpec.describe 'Help' do
  context 'when passing no args to the command' do
    it { expect { Codeowners::Cli::Main.start([]) }.to output(/Commands:/).to_stdout }
  end

  context 'when passing the `check` command' do
    it { expect { Codeowners::Cli::Main.start(%w[help check]) }.to output(/Usage:.*check REPO/m).to_stdout }
  end

  context 'when passing the `config` command' do
    it { expect { Codeowners::Cli::Main.start(%w[help config]) }.to output(/Commands:/m).to_stdout }
  end

  context 'when passing the `fetch` command' do
    it { expect { Codeowners::Cli::Main.start(%w[help fetch]) }.to output(/Commands:/m).to_stdout }
  end

  context 'when passing the `filter` command' do
    it { expect { Codeowners::Cli::Main.start(%w[help filter]) }.to output(/Commands:/m).to_stdout }
  end
end
