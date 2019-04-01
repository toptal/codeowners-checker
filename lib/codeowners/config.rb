# frozen_string_literal: true

Git::Lib.class_eval do
  def config_set(name, value)
    command('config',  [name, value])
  rescue Git::GitExecuteError
    command('config',  ['--add', name, value])
  end

  def config_get(name)
    do_get = proc do |_path|
      command('config', ['--get', name])
    end

    if @git_dir
      Dir.chdir(@git_dir, &do_get)
    else
      do_get.call
    end
  end
end

module Codeowners
  # Default git wrapper without configuration
  class AnonymousGit
    include Git
  end

  # Connfigure and manage the git config file.
  class Config
    def initialize(git = AnonymousGit.new)
      @git = git
    end

    def default_owner
      @git.config('user.owner')
    end

    def default_owner=(name)
      @git.config('user.owner', name)
    end

    def to_h
      {
        default_owner: default_owner
      }
    end
  end
end
