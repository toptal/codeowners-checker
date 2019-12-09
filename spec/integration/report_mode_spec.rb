# frozen_string_literal: true

require 'codeowners/checker'

RSpec.describe 'Report mode' do
  def report_start(codeowners: [], owners: [], file_tree: {}, &block)
    start(codeowners: codeowners, owners: owners, file_tree: file_tree, flags: ['--interactive=f'], &block)
  end

  it 'runs with no-issues reporting' do
    report_start(
      codeowners: ['lib/new_file.rb @mpospelov'],
      owners: ['@mpospelov'],
      file_tree: { 'lib/new_file.rb' => 'bar' }
    ) do
      expect_to_puts('✅ File is consistent')
    end
  end

  it 'runs with missing_ref issue' do
    report_start(file_tree: { 'lib/new_file.rb' => 'bar' }) do
      expect_to_puts('File tmp/test-project/.github/CODEOWNERS is inconsistent:')
      expect_to_puts(
        'No owner defined',
        '------------------------------',
        ['lib/new_file.rb'],
        '------------------------------'
      )
    end
  end

  it 'runs with useless_pattern issue' do
    report_start(
      codeowners: ['lib/new_file.rb @mpospelov', 'liba/* @mpospelov'],
      owners: ['@mpospelov'],
      file_tree: { 'lib/new_file.rb' => 'bar' }
    ) do
      expect_to_puts('File tmp/test-project/.github/CODEOWNERS is inconsistent:')
      expect_to_puts(
        'Useless patterns',
        '------------------------------',
        ['liba/* @mpospelov'],
        '------------------------------'
      )
    end
  end

  it 'runs with invalid_owner issue' do
    report_start(
      codeowners: ['lib/new_file.rb @foobar'],
      owners: ['@mpospelov'],
      file_tree: { 'lib/new_file.rb' => 'bar' }
    ) do
      expect_to_puts('File tmp/test-project/.github/CODEOWNERS is inconsistent:')
      expect_to_puts(
        'Invalid owner',
        '------------------------------',
        ['lib/new_file.rb @foobar'],
        '------------------------------'
      )
    end
  end

  it 'runs with unrecognized_line issue' do
    report_start(
      codeowners: ['lib/new_file.rb @mpospelov', '@mpospelov'],
      owners: ['@mpospelov'],
      file_tree: { 'lib/new_file.rb' => 'bar' }
    ) do
      expect_to_puts('File tmp/test-project/.github/CODEOWNERS is inconsistent:')
      expect_to_puts(
        'Unrecognized line',
        '------------------------------',
        ['@mpospelov'],
        '------------------------------'
      )
    end
  end
end
