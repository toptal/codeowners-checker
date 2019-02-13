# frozen_string_literal: true

require 'git'
module Codeowners
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
