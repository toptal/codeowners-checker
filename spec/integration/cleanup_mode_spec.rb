# frozen_string_literal: true

require 'codeowners/checker'

RSpec.describe 'Report mode' do
  def codeowners_file_body
    File.open(File.join(IntegrationTestRunner::PROJECT_PATH, '.github', 'CODEOWNERS')).read
  end

  def owners_file_body
    File.open(File.join(IntegrationTestRunner::PROJECT_PATH, '.github', 'OWNERS')).read
  end

  subject(:runner) do
    IntegrationTestRunner
      .new(codeowners: codeowners, owners: owners, file_tree: file_tree)
      .run(command: 'cleanup', flags: [])
  end

  let(:codeowners) { [] }
  let(:owners) { [] }
  let(:file_tree) { {} }

  context 'when no issues' do
    let(:codeowners) do
      ['',
       'lib/new_file.rb @user']
    end
    let(:owners) { ['@user'] }
    let(:file_tree) { { 'lib/new_file.rb' => 'bar' } }

    it { is_expected.to report_with('CODEOWNERS was rewritten') }
  end

  context 'when out of order' do
    let(:codeowners) { ['# a', 'b @owner_b', 'a @owner_b', '', 'c @owner_a'] }
    let(:owners) { ['@owner_a', '@owner_b'] }
    let(:file_tree) { { 'a' => 'a', 'b' => 'b', 'c' => 'c' } }

    it 'rewrites codeowner with correct order' do
      expect(runner).to report_with('CODEOWNERS was rewritten')
      expect(codeowners_file_body.strip).to eq([
        '# Owned by @owner_a',
        'c @owner_a',
        '',
        '# Owned by @owner_b',
        'a @owner_b',
        'b @owner_b'
      ].join("\n"))
    end
  end

  context 'when a file has multiple owners' do
    let(:codeowners) { ['file @owner_b @owner_a'] }
    let(:owners) { ['@owner_a', '@owner_b'] }
    let(:file_tree) { { 'file' => 'file' } }

    it 'rewrites codeowner with correct order' do
      expect(runner).to report_with('CODEOWNERS was rewritten')
      expect(codeowners_file_body.strip).to eq([
        '# Owned by @owner_a @owner_b',
        'file @owner_a @owner_b'
      ].join("\n"))
    end
  end

  context 'when a file has a full duplicate entry' do
    let(:codeowners) { ['file @owner', 'file @owner'] }
    let(:owners) { ['@owner'] }
    let(:file_tree) { { 'file' => 'file' } }

    it 'rewrites codeowner with correct order' do
      expect(runner).to report_with('CODEOWNERS was rewritten')
      expect(codeowners_file_body.strip).to eq([
        '# Owned by @owner',
        'file @owner'
      ].join("\n"))
    end
  end

  context 'when a file does not exist' do
    let(:codeowners) { ['**/* @other', 'file @owner', 'a* @owner', 'file/* @owner'] }
    let(:owners) { ['@owner', '@other'] }
    let(:file_tree) { { 'file' => 'file' } }

    it 'rewrites codeowner with correct order' do
      expect(runner).to report_with('CODEOWNERS was rewritten')
      expect(codeowners_file_body.strip).to eq([
        '# Owned by @other',
        '**/* @other',
        '',
        '# Owned by @owner',
        'file @owner'
      ].join("\n"))
    end
  end

  context 'when a file has the same owner twice' do
    let(:codeowners) { ['file @owner @owner'] }
    let(:owners) { ['@owner'] }
    let(:file_tree) { { 'file' => 'file' } }

    it 'rewrites codeowner with correct order' do
      expect(runner).to report_with('CODEOWNERS was rewritten')
      expect(codeowners_file_body.strip).to eq([
        '# Owned by @owner',
        'file @owner'
      ].join("\n"))
    end
  end
end
