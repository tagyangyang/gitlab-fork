# This class is not backed by a table in the main database.
# It loads the latest Pipeline for the HEAD of a repository, and caches that
# in Redis.
module Ci
  class PipelineStatus
    attr_accessor :sha, :status, :project, :loaded

    delegate :commit, to: :project

    def self.load_in_batch_for_projects(projects)
      cached_results_for_projects(projects).zip(projects).each do |result, project|
        project.pipeline_status = Ci::PipelineStatus.new(project, result)
        project.pipeline_status.load_status unless project.pipeline_status.loaded?
      end
    end

    def self.cached_results_for_projects(projects)
      result = Gitlab::Redis.with do |redis|
        redis.multi do
          projects.each do |project|
            cache_key = cache_key_for_project(project)
            redis.exists(cache_key)
            redis.hmget(cache_key, :sha, :status)
          end
        end
      end
      result.each_slice(2).map do |(cache_key_exists, (sha, status))|
        loaded = (cache_key_exists == true)
        { loaded_from_cache: loaded, sha: sha, status: status }
      end
    end

    def self.load_for_project(project)
      new(project).tap do |status|
        status.load_status
      end
    end

    def self.cache_key_for_project(project)
      "projects/#{project.id}/build_status"
    end

    def initialize(project, sha: nil, status: nil, loaded_from_cache: nil)
      @project = project
      @sha = sha
      @status = status
      @has_cache = @loaded = loaded_from_cache
    end

    def has_status?
      loaded? && sha.present? && status.present?
    end

    def load_status
      return if loaded?

      if has_cache?
        load_from_cache
      else
        load_from_commit
        store_in_cache
      end

      self.loaded = true
    end

    def load_from_commit
      return unless commit

      self.sha = commit.sha
      self.status = commit.status
    end

    # We only cache the status for the HEAD commit of a project
    # This status is rendered in project lists
    def store_in_cache_if_needed
      return unless sha
      return delete_from_cache unless commit
      store_in_cache if commit.sha == self.sha
    end

    def load_from_cache
      Gitlab::Redis.with do |redis|
        self.sha, self.status = redis.hmget(cache_key, :sha, :status)
      end
    end

    def store_in_cache
      Gitlab::Redis.with do |redis|
        redis.mapped_hmset(cache_key, { sha: sha, status: status })
      end
    end

    def delete_from_cache
      Gitlab::Redis.with do |redis|
        redis.del(cache_key)
      end
    end

    def has_cache?
      return @has_cache unless @has_cache.nil?

      @has_cache = Gitlab::Redis.with do |redis|
        redis.exists(cache_key)
      end
    end

    def loaded?
      self.loaded
    end

    def cache_key
      self.class.cache_key_for_project(project)
    end
  end
end
