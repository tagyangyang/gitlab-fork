# NamespaceValidator
#
# Custom validator for GitLab namespace values.
#
# Values are checked for formatting and exclusion from a list of reserved path
# names.
class NamespaceValidator < ActiveModel::EachValidator
  # All routes that appear on the top level must be listed here.
  # This will make sure that groups cannot be created with these names
  # as these routes would be masked by the paths already in place.
  #
  # Example:
  #   /api/api-project
  #
  #  the path `api` shouldn't be allowed because it would be masked by `api/*`
  #
  RESERVED = %w[
    .well-known
    admin
    all
    assets
    ci
    dashboard
    files
    groups
    help
    hooks
    issues
    merge_requests
    new
    notes
    profile
    projects
    public
    repository
    robots.txt
    s
    search
    services
    snippets
    teams
    u
    unsubscribes
    users
    api
    autocomplete
    search
    member
    explore
    uploads
    import
    notification_settings
    abuse_reports
    invites
    help
    koding
    health_check
    jwt
    oauth
    sent_notifications
  ].freeze

  # All project routes with wildcard argument must be listed here.
  # Otherwise it can lead to routing issues when route considered as project name.
  #
  # Example:
  #  /group/project/tree/deploy_keys
  #
  #  without tree as reserved name routing can match 'group/project' as group name,
  #  'tree' as project name and 'deploy_keys' as route.
  #
  WILDCARD_ROUTES = %w[tree commits wikis new edit create update logs_tree
                       preview blob blame raw files create_dir find_file
                       artifacts graphs refs badges info git-upload-pack
                       git-receive-pack gitlab-lfs autocomplete_sources
                       templates avatar commit pages compare network snippets
                       services mattermost deploy_keys forks import merge_requests
                       branches merged_branches tags protected_branches variables
                       triggers pipelines environments cycle_analytics builds
                       hooks container_registry milestones labels issues
                       project_members group_links notes noteable boards todos
                       uploads runners runner_projects settings repository
                       transfer remove_fork archive unarchive housekeeping
                       toggle_star preview_markdown export remove_export
                       generate_new_export download_export activity
                       new_issue_address registry].freeze

  STRICT_RESERVED = (RESERVED + WILDCARD_ROUTES).uniq.freeze

  def self.valid_full_path?(full_path)
    pieces = full_path.split('/')
    first_part = pieces.first
    pieces.all? do |namespace|
      type = first_part == namespace ? :top_level : :wildcard
      valid?(namespace, type: type)
    end
  end

  def self.valid?(value, type: :strict)
    !reserved?(value, type: type) && follow_format?(value)
  end

  def self.reserved?(value, type: :strict)
    case type
    when :wildcard
      WILDCARD_ROUTES.include?(value)
    when :top_level
      RESERVED.include?(value)
    else
      STRICT_RESERVED.include?(value)
    end
  end

  def self.follow_format?(value)
    value =~ Gitlab::Regex.namespace_regex
  end

  delegate :reserved?, :follow_format?, to: :class

  def validate_each(record, attribute, value)
    unless follow_format?(value)
      record.errors.add(attribute, Gitlab::Regex.namespace_regex_message)
    end

    if reserved?(value, type: validation_type(record))
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end

  def validation_type(record)
    case record
    when Group
      record.parent_id ? :wildcard : :top_level
    when Project
      :wildcard
    else
      :strict
    end
  end
end
