# frozen_string_literal: true

require 'codeowners/checker'

RSpec.describe 'Report mode' do
  subject(:runner) do
    IntegrationTestRunner
      .new(
        codeowners: codeowners,
        owners: owners,
        file_tree: file_tree,
        flags: ['--interactive=f'] + extra_flags
      )
      .run
  end

  let(:extra_flags) { [] }

  let(:codeowners) { [] }
  let(:owners) { [] }
  let(:file_tree) { {} }

  context 'when no whitelist exists' do
    let(:file_tree) { { 'lib/new_file.rb' => 'bar' } }

    it { is_expected.to warn_with('No whitelist found at tmp/test-project/.github/CODEOWNERS_WHITELIST') }
  end

  context 'when a whitelist exists' do
    let(:file_tree) { { '.github/CODEOWNERS_WHITELIST' => '# ignore files here' } }

    it 'does not warn about a whitelist' do
      expect(runner).not_to warn_with('No whitelist found at tmp/test-project/.github/CODEOWNERS_WHITELIST')
    end
  end

  context 'when no issues' do
    let(:codeowners) { ['lib/new_file.rb @mpospelov'] }
    let(:owners) { ['@mpospelov'] }
    let(:file_tree) { { 'lib/new_file.rb' => 'bar' } }

    it { is_expected.to report_with('✅ File is consistent') }
  end

  context 'when missing_ref issue' do
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

  context 'when all checks enabled' do
    let(:codeowners) do
      [
        'file_invalid_owner @invalid_owner',
        'useless_pattern @owner',
        '@unrecognized_line'
      ]
    end
    let(:owners) { ['@owner'] }
    let(:file_tree) do
      {
        'file_missing_ref' => 'bar',
        'file_invalid_owner' => 'baz'
      }
    end

    context 'without invalid owner check' do
      let(:extra_flags) { ['--no-check-invalid-owner'] }

      it 'does not report invalid owner' do
        expect(runner.reports.join("\n")).not_to include('Invalid owner')
      end
    end

    context 'without missing ref check' do
      let(:extra_flags) { ['--no-check-missing-ref'] }

      it 'does not report missing ref' do
        expect(runner.reports.join("\n")).not_to include('No owner defined')
      end
    end

    context 'without unrecognized line check' do
      let(:extra_flags) { ['--no-check-unrecognized-line'] }

      it 'does not report unrecognized line' do
        expect(runner.reports.join("\n")).not_to include('Unrecognized line')
      end
    end

    context 'without useless pattern check' do
      let(:extra_flags) { ['--no-check-useless-pattern'] }

      it 'does not report useless pattern' do
        expect(runner.reports.join("\n")).not_to include('Useless patterns')
      end
    end
  end
end
