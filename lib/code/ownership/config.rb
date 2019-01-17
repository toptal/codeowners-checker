
Git::Lib.class_eval do
  def config_set name, value
    command('config',  [ name, value])
  rescue
    command('config',  ["--add", name, value])
  end
  def config_get(name)
    do_get = Proc.new do |path|
      command('config', ['--get', name])
    end

    if @git_dir
      Dir.chdir(@git_dir, &do_get)
    else
      do_get.call
    end
  end
end

module Code
  module Ownership
    class AnonymousGit
      include Git
    end

    class Config
      def initialize git = AnonymousGit.new
        @git = git
      end

      def default_team
        @git.config("user.team")
      end

      def default_team= name
        @git.config("user.team", name)
      end
    end
  end
end
