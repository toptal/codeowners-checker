# frozen_string_literal: true

RSpec.describe Codeowners::Cli::Warner do
  describe '.check_warnings' do
    it 'calls warn_github_env if ENV["GITHUB_ORGANIZATION"] is set' do
      ENV['GITHUB_ORGANIZATION'] = 'toptal'
      expect(described_class).to receive(:warn).with(/Usage of GITHUB_ORGANIZATION ENV variable has been deprecated/)
      described_class.check_warnings
    end

    it 'does not call warn_github_env if ENV["GITHUB_ORGANIZATION"] is not set' do
      ENV['GITHUB_ORGANIZATION'] = ''
      expect(described_class).not_to receive(:warn)
    end

    it 'does not call warn_github_env if ENV["GITHUB_ORGANIZATION"] is nil' do
      ENV['GITHUB_ORGANIZATION'] = nil
      expect(described_class).not_to receive(:warn)
    end
  end

  describe '.warn' do
    it 'outputs messages to stdout with a warning' do
      expect { described_class.warn('message') }.to output("[WARNING] message\n").to_stdout
    end
  end
end
