# frozen_string_literal: true

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
end
