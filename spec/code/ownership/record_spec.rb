# frozen_string_literal: true

require 'code/ownership/record'

RSpec.describe Code::Ownership::Record do
  let(:sample) { ['.rubocop.yml', %w[@jonatas], 1, ['# Linters']] }
  let(:multiple_teams) { ['Gemfile', %w[@toptal/rogue-one @toptal/secops], 3, ['# Libraries']] }
  let(:any_file_from_team) { ['lib/billing/*', %w[@toptal/billing], 5, ['# Team specific', '# Billing Team']] }
  let(:any_folder_from_team) { ['lib/billing/*/*', %w[@toptal/billing], 8, []] }

  describe '#to_row' do
    context 'with sample' do
      subject { described_class.new(*sample).to_row }

      it { is_expected.to eq(<<~OUTPUT.chomp) }
        # Linters
        .rubocop.yml @jonatas
      OUTPUT
    end

    context 'with multiple teams' do
      subject { described_class.new(*multiple_teams).to_row }

      it { is_expected.to eq(<<~OUTPUT.chomp) }
        # Libraries
        Gemfile @toptal/rogue-one @toptal/secops
      OUTPUT
    end

    context 'with patterns' do
      subject { described_class.new(*any_file_from_team).to_row }

      it { is_expected.to eq(<<~OUTPUT.chomp) }
        # Team specific
        # Billing Team
        lib/billing/* @toptal/billing
      OUTPUT
    end
  end

  describe '#regex' do
    context 'with sample' do
      subject { described_class.new(*sample).regex }

      it { is_expected.to eq(/.rubocop.yml/) }
    end

    context 'with pattern for any file' do
      subject { described_class.new(*any_file_from_team).regex }

      it { is_expected.to eq(%r{lib/billing/[^/]+}) }
    end

    context 'with pattern for any folder' do
      subject { described_class.new(*any_folder_from_team).regex }

      it { is_expected.to eq(%r{lib/billing/[^/]+/[^/]+}) }
    end
  end

  describe '#suggest_files_for_pattern' do
    context 'when passing sample file in the root folder.' do
      subject { described_class.new(*sample).suggest_files_for_pattern }

      it 'picks the current files in the folder' do
        expect(subject).to eq(Dir['*'])
      end
    end

    context 'when passing a folder with multiple *' do
      subject { described_class.new(*any_folder_from_team).suggest_files_for_pattern }

      it 'picks all files from parent folder of the pattern' do
        allow(Dir).to receive('[]').with('lib/billing/*')
        subject
      end
    end

    context 'when pattern have a star' do
      subject { described_class.new(*any_file_from_team).suggest_files_for_pattern }

      it 'picks all files from parent folder of the pattern' do
        allow(Dir).to receive('[]').with('lib/billing/*')
        subject
      end
    end
  end
end
