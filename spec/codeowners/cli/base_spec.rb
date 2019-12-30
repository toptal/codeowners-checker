# frozen_string_literal: true

RSpec.describe Codeowners::Cli::Base do
  subject(:cli) { described_class.new }

  describe 'initialization' do
    it 'checks for warnings' do
      expect(Codeowners::Cli::Warner).to receive(:check_warnings)
      cli
    end
  end
end
