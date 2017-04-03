require 'tempfile'

module Projects
  class UpdatePagesService < BaseService
    BLOCK_SIZE = 32.kilobytes
    MAX_SIZE = 1.terabyte
    SITE_PATH = 'public/'.freeze

    attr_reader :job

    def initialize(project, job)
      @project, @job = project, job
    end

    def execute
      # Create status notifying the deployment of pages
      @status = create_status
      @status.enqueue!
      @status.run!

      raise 'missing pages artifacts' unless job.artifacts_file?
      raise 'pages are outdated' unless latest?

      # Create temporary directory in which we will extract the artifacts
      FileUtils.mkdir_p(tmp_path)
      Dir.mktmpdir(nil, tmp_path) do |archive_path|
        extract_archive!(archive_path)

        # Check if we did extract public directory
        archive_public_path = File.join(archive_path, 'public')
        raise 'pages miss the public folder' unless Dir.exist?(archive_public_path)
        raise 'pages are outdated' unless latest?

        deploy_page!(archive_public_path)
        success
      end
    rescue => e
      error(e.message)
    ensure
      job.erase_artifacts! unless job.has_expiring_artifacts?
      temp_file&.close
      temp_file&.unlink
    end

    private

    def success
      @status.success
      super
    end

    def error(message, http_status = nil)
      @status.allow_failure = !latest?
      @status.description = message
      @status.drop
      super
    end

    def create_status
      GenericCommitStatus.new(
        project: project,
        pipeline: job.pipeline,
        user: job.user,
        ref: job.ref,
        stage: 'deploy',
        name: 'pages:deploy'
      )
    end

    def extract_archive!(temp_path)
      if artifacts.ends_with?('.tar.gz') || artifacts.ends_with?('.tgz')
        extract_tar_archive!(temp_path)
      elsif artifacts.ends_with?('.zip')
        extract_zip_archive!(temp_path)
      else
        raise 'unsupported artifacts format'
      end
    end

    def extract_tar_archive!(temp_path)
      results = Open3.pipeline(%W(gunzip -c #{extractable_artifacts}),
                               %W(dd bs=#{BLOCK_SIZE} count=#{blocks}),
                               %W(tar -x -C #{temp_path} #{SITE_PATH}),
                               err: '/dev/null')

      raise 'pages failed to extract' unless results.compact.all?(&:success?)
    end

    def extract_zip_archive!(temp_path)
      # Requires UnZip at least 6.00 Info-ZIP.
      # -n  never overwrite existing files
      # We add * to end of SITE_PATH, because we want to extract SITE_PATH and all subdirectories
      site_path = File.join(SITE_PATH, '*')
      unless system(*%W(unzip -n #{extractable_artifacts} #{site_path} -d #{temp_path}))
        raise 'pages failed to extract'
      end
    end

    def deploy_page!(archive_public_path)
      # Do atomic move of pages
      # Move and removal may not be atomic, but they are significantly faster then extracting and removal
      # 1. We move deployed public to previous public path (file removal is slow)
      # 2. We move temporary public to be deployed public
      # 3. We remove previous public path
      FileUtils.mkdir_p(pages_path)
      begin
        FileUtils.move(public_path, previous_public_path)
      rescue
      end
      FileUtils.move(archive_public_path, public_path)
    ensure
      FileUtils.rm_r(previous_public_path, force: true)
    end

    def latest?
      # check if sha for the ref is still the most recent one
      # this helps in case when multiple deployments happens
      sha == latest_sha
    end

    def blocks
      # Calculate dd parameters: we limit the size of pages
      1 + max_size / BLOCK_SIZE
    end

    def max_size
      current_application_settings.max_pages_size.megabytes || MAX_SIZE
    end

    def tmp_path
      @tmp_path ||= File.join(::Settings.pages.path, 'tmp')
    end

    def pages_path
      @pages_path ||= project.pages_path
    end

    def public_path
      @public_path ||= File.join(pages_path, 'public')
    end

    def previous_public_path
      @previous_public_path ||= File.join(pages_path, "public.#{SecureRandom.hex}")
    end

    def ref
      job.ref
    end

    def artifacts
      job.artifacts_file.path
    end

    # If we're using S3 for storage, we first need to read all the data.
    # This is done using a tempfile as artifacts will be GC'ed
    def extractable_artifacts
      if Gitlab.config.artifacts.object_store.enabled
        artifacts
      else
        temp_file.path
      end
    end

    def temp_file
      @temp_file ||=
        begin
          file = Tempfile.new("pages-artifacts-#{job.id}")
          File.open(file, 'wb') { file.write(job.artifacts_file.read) }

          file
        end
    end

    def latest_sha
      project.commit(job.ref).try(:sha).to_s
    end

    def sha
      job.sha
    end
  end
end
