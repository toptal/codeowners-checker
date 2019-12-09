# frozen_string_literal: true

module IntegrationTestHelper
  PROJECT_PATH = File.join('tmp', 'test-project')
  # NOTE: due to hight usage of plain #puts we can't rely on RSpec output matcher
  def expect_to_puts(*args)
    expect(STDOUT).to receive(:puts).with(*args).and_call_original
  end

  def expect_not_to_puts
    expect(STDOUT).not_to receive(:puts)
  end

  # rubocop: disable RSpec/AnyInstance
  def expect_to_ask(question, limited_to: %w[y i q])
    expect_any_instance_of(Thor).to receive(:ask).with(question, limited_to: limited_to) do
      yield if block_given?
    end
  end
  # rubocop: enable RSpec/AnyInstance

  # rubocop: disable Lint/HandleExceptions
  def start(codeowners: [], owners: [], file_tree: {}, flags: [])
    setup_project(codeowners: codeowners, file_tree: file_tree, owners: owners)
    flags.push('--from=HEAD~1')
    yield
    begin
      Codeowners::Cli::Main.start(['check', PROJECT_PATH, *flags])
    rescue SystemExit
    end
  end
  # rubocop: enable Lint/HandleExceptions

  def create_file_tree(tree)
    tree.each do |file_path, content|
      unless File.exist?(file_path)
        parts = file_path.split('/')
        dir_parts = parts[0..-2]
        FileUtils.mkdir_p(File.join(*dir_parts)) unless dir_parts.empty?
      end
      File.write(file_path, content)
    end
  end

  # rubocop: disable Metrics/AbcSize
  # rubocop: disable Metrics/MethodLength
  def setup_project(codeowners: [], file_tree: {}, owners: [])
    Dir.mkdir('tmp') unless Dir.exist?('tmp')
    FileUtils.rm_r(PROJECT_PATH) if Dir.exist?(PROJECT_PATH)
    Dir.mkdir(PROJECT_PATH)
    Dir.chdir(PROJECT_PATH) do
      Git.init
      git = Git.open('.', logger: Logger.new(STDOUT))
      Dir.mkdir('.github')
      File.write(File.join('.github', 'CODEOWNERS'), codeowners.join("\n"))
      File.write(File.join('.github', 'OWNERS'), owners.join("\n"))
      git.add(all: true)
      git.commit('First commit :yay:')
      create_file_tree(file_tree)
      git.add(all: true)
      git.commit('File tree created')
    end
  end
  # rubocop: enable Metrics/AbcSize
  # rubocop: enable Metrics/MethodLength
end
