class PipelineSerializer < BaseSerializer
  InvalidResourceError = Class.new(StandardError)

  entity PipelineEntity

  def with_pagination(request, response)
    tap { @paginator = Gitlab::Serializer::Pagination.new(request, response) }
  end

  def paginated?
    @paginator.present?
  end

  def represent(resource, opts = {})
    if resource.is_a?(ActiveRecord::Relation)
      resource = resource.preload(:user, :statuses, project: :namespace)

      if paginated?
        resource = @paginator.paginate(resource)
      end

      preload_commit_authors(resource)
    end

    super(resource, opts)
  end

  def represent_status(resource)
    return {} unless resource.present?

    data = represent(resource, { only: [{ details: [:status] }] })
    data.dig(:details, :status) || {}
  end

  private

  def preload_commit_authors(resource)
    emails = resource.map(&:git_author_email).map(&:downcase).uniq
    commit_authors = find_users_by_emails(emails)
    author_map = index_users_by_emails(commit_authors)

    resource.each do |pipeline|
      pipeline.commit.author = author_map[pipeline.git_author_email]
    end
  end

  def find_users_by_emails(emails)
    sql = <<-SQL.strip_heredoc
      SELECT users.*, emails.email AS alternative_email
        FROM users LEFT OUTER JOIN emails ON emails.user_id = users.id
        WHERE users.email IN (?)
        OR emails.email in (?)
    SQL

    User.find_by_sql([sql, emails, emails])
  end

  def index_users_by_emails(commit_authors)
    commit_authors.index_by do |author|
      author.alternative_email || author.email
    end
  end
end
