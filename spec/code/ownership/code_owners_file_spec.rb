# frozen_string_literal: true

RSpec.describe Code::Ownership::CodeOwnersFile do
  let(:content) { <<~FILE.lines }
    # Linters
    .rubocop.yml @jonatas
    # Libraries
    Gemfile @toptal/rogue-one @toptal/secops

    # Team related code
    # Billing related
    lib/billing/* @toptal/billing
  FILE

  describe '#parse!' do
    subject { described_class.new(content).parse! }
    it 'returns a list of Ownership' do
      is_expected.to be_a(Array)
      expect(subject.first).to be_a(Code::Ownership::Record)
    end

    it 'parses rubocop info with comments and owner' do
      rubocop_spec = subject.first
      expect(rubocop_spec.comments).to include('# Linters')
      expect(rubocop_spec.pattern).to eq('.rubocop.yml')
      expect(rubocop_spec.owners).to include('@jonatas')
      expect(rubocop_spec.line).to eq(2)
    end

    it 'parses info with multiple owners' do
      gemfile_spec = subject[1]
      expect(gemfile_spec.comments).to include('# Libraries')
      expect(gemfile_spec.pattern).to eq('Gemfile')
      expect(gemfile_spec.owners).to match_array(%w[@toptal/rogue-one @toptal/secops])
      expect(gemfile_spec.line).to eq(4)
    end

    it 'creates a regex based on pattern' do
      billing_spec = subject[2]
      expect(billing_spec.comments).to match_array(['', '# Team related code', '# Billing related'])
      expect(billing_spec.pattern).to eq('lib/billing/*')
      expect(billing_spec.regex).to eq(%r{lib/billing/[^/]+})
      expect(billing_spec.owners).to match_array(%w[@toptal/billing])
      expect(billing_spec.line).to eq(8)
    end
  end

  describe '#update' do
    subject { described_class.new(content) }

    before  { subject.parse! }

    it 'fails if the line number is wrong' do
      expect do
        subject.update line: 1, pattern: '.rubocop*'
      end.to raise_error(/no patterns with line: 1/)
    end

    it 'rewrite the owners attributes' do
      expect do
        subject.update line: 2, pattern: '.rubocop*', owners: %w[@other]
      end.to change { subject.owners[0].pattern }
        .from('.rubocop.yml').to('.rubocop*')
        .and change { subject.owners[0].owners }
        .from(['@jonatas']).to(['@other'])
    end
  end

  describe '#insert' do
    subject { described_class.new(content) }

    before  { subject.parse! }

    it 'rewrite the owners attributes' do
      expect do
        subject.insert after_line: 2, pattern: '.rubocop*', owners: %w[@other]
      end.to change { subject.owners.length }.from(3).to(4)
    end
  end

  describe '#delete' do
    subject { described_class.new(content) }

    before  { subject.parse! }

    it 'rewrite the owners attributes' do
      expect do
        subject.delete line: 2
      end.to change { subject.owners.length }.from(3).to(2)
    end

    it 'fails with the wrong line number' do
      expect do
        subject.delete line: 99_999
      end.to raise_error("couldn't find record with line 99999")
    end
  end

  describe 'process_content!' do
    subject { described_class.new(content) }
    before  { subject.parse! }

    it 'changes content in memory' do
      subject.update line: 2, pattern: '.rubocop*', owners: %w[@other]
      subject.update line: 4, owners: %w[@toptal/secops]
      subject.update line: 8, comments: ['# Billing related']
      expect(subject.process_content!).to eq(<<~CONTENT.chomp)
        # Linters
        .rubocop* @other
        # Libraries
        Gemfile @toptal/secops
        # Billing related
        lib/billing/* @toptal/billing
      CONTENT
    end
  end
end
