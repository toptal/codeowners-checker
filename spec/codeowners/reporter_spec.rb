# frozen_string_literal: true

require 'codeowners/checker'

RSpec.describe Codeowners::Reporter do
  describe '::print_delimiter_line' do
    it 'raises the exception if unknow error type' do
      expect do
        described_class.print_delimiter_line(:foobar)
      end.to raise_exception(ArgumentError, "unknown error type 'foobar'")
    end

    it 'puts missing_ref label' do
      expect do
        described_class.print_delimiter_line(:missing_ref)
      end.to output(<<~OUTPUT).to_stdout
        ------------------------------
        No owner defined
        ------------------------------
      OUTPUT
    end

    it 'puts useless_pattern label' do
      expect do
        described_class.print_delimiter_line(:useless_pattern)
      end.to output(<<~OUTPUT).to_stdout
        ------------------------------
        Useless patterns
        ------------------------------
      OUTPUT
    end

    it 'puts invalid_owner label' do
      expect do
        described_class.print_delimiter_line(:invalid_owner)
      end.to output(<<~OUTPUT).to_stdout
        ------------------------------
        Invalid owner
        ------------------------------
      OUTPUT
    end

    it 'puts unrecognized_line label' do
      expect do
        described_class.print_delimiter_line(:unrecognized_line)
      end.to output(<<~OUTPUT).to_stdout
        ------------------------------
        Unrecognized line
        ------------------------------
      OUTPUT
    end
  end

  describe '::print_error' do
    it 'puts common error' do
      expect do
        described_class.print_error(:unrecognized_line, 'foobar', ['baz'])
      end.to output("foobar\n").to_stdout
    end

    it 'puts invalid_owner with missing' do
      expect do
        described_class.print_error(:invalid_owner, 'foobar', %w[baz gaz])
      end.to output("foobar MISSING: baz, gaz\n").to_stdout
    end
  end

  describe '::print' do
    it 'forwards args to puts' do
      expect do
        described_class.print('foobar', 'baz')
      end.to output("foobar\nbaz\n").to_stdout
    end
  end
end
