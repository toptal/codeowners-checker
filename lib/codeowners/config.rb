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

    def default_organization
      config_org = @git.config('user.organization')
      return config_org.strip unless config_org.nil? || config_org.strip.empty?

      parse_organization_from_origin
    end

    def default_organization=(name)
      @git.config('user.organization', name)
    end

    def to_h
      {
        default_owner: default_owner,
        default_organization: default_organization
      }
    end

    protected

    def parse_organization_from_origin
      origin_url = @git.config('remote.origin.url')
      return '' if origin_url.nil? || origin_url.strip.empty?

      org_regexp = origin_url.match(%r{:(?<org>.+?)/})
      return '' if org_regexp.nil? || org_regexp[:org].strip.empty?

      org_regexp[:org].strip
    end
  end
end
