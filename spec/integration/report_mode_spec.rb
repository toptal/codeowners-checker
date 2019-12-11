# frozen_string_literal: true

require 'codeowners/checker'

RSpec.describe 'Report mode' do
  subject(:runner) do
    IntegrationTestRunner
      .new(codeowners: codeowners, owners: owners, file_tree: file_tree, flags: ['--interactive=f'])
      .run
  end

  let(:codeowners) { [] }
  let(:owners) { [] }
  let(:file_tree) { {} }

  context 'when no issues' do
    let(:codeowners) { ['lib/new_file.rb @mpospelov'] }
    let(:owners) { ['@mpospelov'] }
    let(:file_tree) { { 'lib/new_file.rb' => 'bar' } }

    it { is_expected.to report_with('✅ File is consistent') }
  end

  context 'when owner_defined issue' do
    let(:file_tree) { { 'lib/new_file.rb' => 'bar' } }

    it 'reports missing owner file' do
      expect(runner).to report_with(
        'File tmp/test-project/.github/CODEOWNERS is inconsistent:',
        '------------------------------',
        'No owner defined',
        '------------------------------',
        'lib/new_file.rb'
      )
    end
  end

  context 'when useless_pattern issue' do
    let(:codeowners) { ['lib/new_file.rb @mpospelov', 'liba/* @mpospelov'] }
    let(:owners) { ['@mpospelov'] }
    let(:file_tree) { { 'lib/new_file.rb' => 'bar' } }

    it 'reports useless paterns from codeowners' do
      expect(runner).to report_with(
        'File tmp/test-project/.github/CODEOWNERS is inconsistent:',
        '------------------------------',
        'Useless patterns',
        '------------------------------',
        'liba/* @mpospelov'
      )
    end
  end

  context 'when invalid_owner issue' do
    let(:codeowners) { ['lib/new_file.rb @mpospelov @foobar'] }
    let(:owners) { ['@mpospelov'] }
    let(:file_tree) { { 'lib/new_file.rb' => 'bar' } }

    it 'reports with invalid owner with missing owners' do
      expect(runner).to report_with(
        'File tmp/test-project/.github/CODEOWNERS is inconsistent:',
        '------------------------------',
        'Invalid owner',
        '------------------------------',
        'lib/new_file.rb @mpospelov @foobar MISSING: @foobar'
      )
    end
  end

  context 'when unrecognized_line issue' do
    let(:codeowners) { ['lib/new_file.rb @mpospelov', '@mpospelov'] }
    let(:owners) { ['@mpospelov'] }
    let(:file_tree) { { 'lib/new_file.rb' => 'bar' } }

    it 'reports with unrecognized lines list' do
      expect(runner).to report_with(
        'File tmp/test-project/.github/CODEOWNERS is inconsistent:',
        '------------------------------',
        'Unrecognized line',
        '------------------------------',
        '@mpospelov'
      )
    end
  end
end
