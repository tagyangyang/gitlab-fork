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
      resource = resource.preload(
        :user,
        statuses: { project: [:project_feature, :namespace] },
        project: :namespace)

      if paginated?
        resource = @paginator.paginate(resource)
      end

      preload_commit_authors(resource)
    elsif paginated?
      raise Gitlab::Serializer::Pagination::InvalidResourceError
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
    emails = find_unique_author_emails(resource)
    authors = find_authors_by_emails(emails)
    author_map = index_authors_by_emails(authors)

    resource.each do |pipeline|
      # Using safe navigator would always construct the arguments, bad.
      # rubocop:disable Style/SafeNavigation
      if pipeline.commit
        pipeline.commit.author = author_map[pipeline.git_author_email]
      end
    end
  end

  def find_unique_author_emails(resource)
    emails = Set.new

    resource.each do |r|
      emails << r.git_author_email.downcase if r.git_author_email
    end

    emails.to_a
  end

  def find_authors_by_emails(emails)
    sql = <<-SQL.strip_heredoc
      SELECT users.*, emails.email AS alternative_email
        FROM users LEFT OUTER JOIN emails ON emails.user_id = users.id
        WHERE users.email IN (?)
        OR emails.email in (?)
    SQL

    User.find_by_sql([sql, emails, emails])
  end

  def index_authors_by_emails(authors)
    authors.index_by do |a|
      a.alternative_email || a.email
    end
  end
end
