# frozen_string_literal: true

require 'fileutils'

module Helpers
  # stub ENV values according to examples and resets them after the test finishes
  # this method should be used with an around block like so:
  # around { |example| with_env('SOME' => 'VALUE') { example.run } }
  def with_env(env)
    previous_env = {}
    env.each do |key, value|
      previous_env[key] = ENV[key]
      ENV[key] = value
    end
    yield
    previous_env.each do |key, value|
      ENV[key] = value
    end
  end

  # Move current dir to folder and creates it if it doesn't exists
  def on_dirpath(folder_name)
    Dir.mkdir(folder_name) unless Dir.exist?(folder_name)
    Dir.chdir(folder_name) do
      yield
    end
  end

  def create_dir(dirpath)
    FileUtils.mkdir_p(dirpath)
  end

  def remove_dir(dirpath)
    FileUtils.rm_r(dirpath) if Dir.exist?(dirpath)
  end

  def remove_file(filepath)
    FileUtils.rm_f(filepath)
  end

  def move_dir(dirpath, new_dirpath)
    FileUtils.mv(dirpath, new_dirpath)
  end

  def setup_owners_list(filename = '.github/OWNERS')
    File.open(filename, 'w+') do |file|
      file.puts <<~CONTENT
        @owner
        @owner1
        @owner2
      CONTENT
    end
  end
end
