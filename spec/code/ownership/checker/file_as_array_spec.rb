# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

require 'code/ownership/checker/file_as_array'

RSpec.describe Code::Ownership::Checker::FileAsArray do
  subject { described_class.new(file_path) }

  let!(:tmp_dir) { Dir.mktmpdir }
  let(:file_path) { File.join(tmp_dir, 'test.txt') }

  after { FileUtils.rm_rf(tmp_dir) }

  describe '#content' do
    context 'when the file exist' do
      let(:lines) { ['line 1', '', 'line 2'] }
      let(:content) { <<~FILE }
        line 1

        line 3
      FILE

      before do
        File.open(file_path, 'w+') do |f|
          f.puts(content)
        end
      end

      it 'returns the file lines' do
        expect(subject.content).to eq(lines)
      end
    end

    context 'when the file does not exist' do
      it 'returns empty array' do
        expect(subject.content).to eq([])
      end
    end
  end

  describe '#content=' do
    let(:lines) { ['line 1', 'line 2'] }
    let(:content) { <<~FILE }
      line 1
      line 2
    FILE

    context 'when the file exist' do
      before do
        File.open(file_path, 'w+') do |f|
          f.puts('')
        end
      end

      it 'over-writes the file with content' do
        subject.content = lines
        expect(File.read(file_path)).to eq(content)
      end
    end

    context 'when the file does not exist' do
      it 'creates the file with content' do
        expect do
          subject.content = lines
        end.to change { File.exist?(file_path) }.from(false).to(true)

        expect(File.read(file_path)).to eq(content)
      end
    end
  end
end
