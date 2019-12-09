# frozen_string_literal: true

require 'pry'
require 'fileutils'
require 'codeowners/checker'

RSpec.describe 'Report mode' do
  def start(project_name)
    Codeowners::Cli::Main.start(['check', project_fixture_path(project_name), '--interactive=f'])
  end

  it 'runs with no-issues reporting' do
    expect_to_puts('✅ File is consistent')
    start('no-issues')
  end
end
