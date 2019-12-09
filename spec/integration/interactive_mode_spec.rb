# frozen_string_literal: true

require 'fileutils'
require 'codeowners/checker'

RSpec.describe 'Interactive mode' do
  def start(project_name)
    Codeowners::Cli::Main.start(['check', project_fixture_path(project_name)])
  end

  it 'runs without reporting' do
    expect_not_to_puts
    start('no-issues')
  end
end
