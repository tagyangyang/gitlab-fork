require 'securerandom'

module Gitlab
  class Shell
    Error = Class.new(StandardError)

    KeyAdder = Struct.new(:io) do
      def add_key(id, key)
        key = Gitlab::Shell.strip_key(key)
        # Newline and tab are part of the 'protocol' used to transmit id+key to the other end
        if key.include?("\t") || key.include?("\n")
          raise Error.new("Invalid key: #{key.inspect}")
        end

        io.puts("#{id}\t#{key}")
      end
    end

    class << self
      def secret_token
        @secret_token ||= begin
          File.read(Gitlab.config.gitlab_shell.secret_file).chomp
        end
      end

      def ensure_secret_token!
        return if File.exist?(File.join(Gitlab.config.gitlab_shell.path, '.gitlab_shell_secret'))

        generate_and_link_secret_token
      end

      def version_required
        @version_required ||= File.read(Rails.root.
                                        join('GITLAB_SHELL_VERSION')).strip
      end

      def strip_key(key)
        key.split(/[ ]+/)[0, 2].join(' ')
      end

      private

      # Create (if necessary) and link the secret token file
      def generate_and_link_secret_token
        secret_file = Gitlab.config.gitlab_shell.secret_file
        shell_path = Gitlab.config.gitlab_shell.path

        unless File.size?(secret_file)
          # Generate a new token of 16 random hexadecimal characters and store it in secret_file.
          @secret_token = SecureRandom.hex(16)
          File.write(secret_file, @secret_token)
        end

        link_path = File.join(shell_path, '.gitlab_shell_secret')
        if File.exist?(shell_path) && !File.exist?(link_path)
          FileUtils.symlink(secret_file, link_path)
        end
      end
    end

    # Init new repository
    #
    # storage - project's storage path
    # name - project path with namespace
    #
    # Ex.
    #   add_repository("/path/to/storage", "gitlab/gitlab-ci")
    #
    def add_repository(storage, name)
      Gitlab::Utils.system_silent([gitlab_shell_projects_path,
                                   'add-project', storage, "#{name}.git"])
    end

    # Import repository
    #
    # storage - project's storage path
    # name - project path with namespace
    #
    # Ex.
    #   import_repository("/path/to/storage", "gitlab/gitlab-ci", "https://github.com/randx/six.git")
    #
    def import_repository(storage, name, url)
      # Timeout should be less than 900 ideally, to prevent the memory killer
      # to silently kill the process without knowing we are timing out here.
      output, status = Popen.popen([gitlab_shell_projects_path, 'import-project',
                                    storage, "#{name}.git", url, '800'])
      raise Error, output unless status.zero?
      true
    end

    # Fetch remote for repository
    #
    # name - project path with namespace
    # remote - remote name
    # forced - should we use --force flag?
    # no_tags - should we use --no-tags flag?
    #
    # Ex.
    #   fetch_remote("gitlab/gitlab-ci", "upstream")
    #
    def fetch_remote(storage, name, remote, forced: false, no_tags: false)
      args = [gitlab_shell_projects_path, 'fetch-remote', storage, "#{name}.git", remote, '800']
      args << '--force' if forced
      args << '--no-tags' if no_tags

      output, status = Popen.popen(args)
      raise Error, output unless status.zero?
      true
    end

    # Move repository
    # storage - project's storage path
    # path - project path with namespace
    # new_path - new project path with namespace
    #
    # Ex.
    #   mv_repository("/path/to/storage", "gitlab/gitlab-ci", "randx/gitlab-ci-new")
    #
    def mv_repository(storage, path, new_path)
      Gitlab::Utils.system_silent([gitlab_shell_projects_path, 'mv-project',
                                   storage, "#{path}.git", "#{new_path}.git"])
    end

    # Fork repository to new namespace
    # forked_from_storage - forked-from project's storage path
    # path - project path with namespace
    # forked_to_storage - forked-to project's storage path
    # fork_namespace - namespace for forked project
    #
    # Ex.
    #  fork_repository("/path/to/forked_from/storage", "gitlab/gitlab-ci", "/path/to/forked_to/storage", "randx")
    #
    def fork_repository(forked_from_storage, path, forked_to_storage, fork_namespace)
      Gitlab::Utils.system_silent([gitlab_shell_projects_path, 'fork-project',
                                   forked_from_storage, "#{path}.git", forked_to_storage,
                                   fork_namespace])
    end

    # Remove repository from file system
    #
    # storage - project's storage path
    # name - project path with namespace
    #
    # Ex.
    #   remove_repository("/path/to/storage", "gitlab/gitlab-ci")
    #
    def remove_repository(storage, name)
      Gitlab::Utils.system_silent([gitlab_shell_projects_path,
                                   'rm-project', storage, "#{name}.git"])
    end

    # Add new key to gitlab-shell
    #
    # Ex.
    #   add_key("key-42", "sha-rsa ...")
    #
    def add_key(key_id, key_content)
      Gitlab::Utils.system_silent([gitlab_shell_keys_path,
                                   'add-key', key_id, self.class.strip_key(key_content)])
    end

    # Batch-add keys to authorized_keys
    #
    # Ex.
    #   batch_add_keys { |adder| adder.add_key("key-42", "sha-rsa ...") }
    def batch_add_keys(&block)
      IO.popen(%W(#{gitlab_shell_path}/bin/gitlab-keys batch-add-keys), 'w') do |io|
        yield(KeyAdder.new(io))
      end
    end

    # Remove ssh key from gitlab shell
    #
    # Ex.
    #   remove_key("key-342", "sha-rsa ...")
    #
    def remove_key(key_id, key_content)
      Gitlab::Utils.system_silent([gitlab_shell_keys_path,
                                   'rm-key', key_id, key_content])
    end

    # Remove all ssh keys from gitlab shell
    #
    # Ex.
    #   remove_all_keys
    #
    def remove_all_keys
      Gitlab::Utils.system_silent([gitlab_shell_keys_path, 'clear'])
    end

    # Add empty directory for storing repositories
    #
    # Ex.
    #   add_namespace("/path/to/storage", "gitlab")
    #
    def add_namespace(storage, name)
      path = full_path(storage, name)
      FileUtils.mkdir_p(path, mode: 0770) unless exists?(storage, name)
    rescue Errno::EEXIST => e
      Rails.logger.warn("Directory exists as a file: #{e} at: #{path}")
    end

    # Remove directory from repositories storage
    # Every repository inside this directory will be removed too
    #
    # Ex.
    #   rm_namespace("/path/to/storage", "gitlab")
    #
    def rm_namespace(storage, name)
      FileUtils.rm_r(full_path(storage, name), force: true)
    end

    # Move namespace directory inside repositories storage
    #
    # Ex.
    #   mv_namespace("/path/to/storage", "gitlab", "gitlabhq")
    #
    def mv_namespace(storage, old_name, new_name)
      return false if exists?(storage, new_name) || !exists?(storage, old_name)

      FileUtils.mv(full_path(storage, old_name), full_path(storage, new_name))
    end

    def url_to_repo(path)
      Gitlab.config.gitlab_shell.ssh_path_prefix + "#{path}.git"
    end

    # Return GitLab shell version
    def version
      gitlab_shell_version_file = "#{gitlab_shell_path}/VERSION"

      if File.readable?(gitlab_shell_version_file)
        File.read(gitlab_shell_version_file).chomp
      end
    end

    # Check if such directory exists in repositories.
    #
    # Usage:
    #   exists?(storage, 'gitlab')
    #   exists?(storage, 'gitlab/cookies.git')
    #
    def exists?(storage, dir_name)
      File.exist?(full_path(storage, dir_name))
    end

    protected

    def gitlab_shell_path
      Gitlab.config.gitlab_shell.path
    end

    def gitlab_shell_user_home
      File.expand_path("~#{Gitlab.config.gitlab_shell.ssh_user}")
    end

    def full_path(storage, dir_name)
      raise ArgumentError.new("Directory name can't be blank") if dir_name.blank?

      File.join(storage, dir_name)
    end

    def gitlab_shell_projects_path
      File.join(gitlab_shell_path, 'bin', 'gitlab-projects')
    end

    def gitlab_shell_keys_path
      File.join(gitlab_shell_path, 'bin', 'gitlab-keys')
    end
  end
end
