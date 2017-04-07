# NamespaceValidator
#
# Custom validator for GitLab namespace values.
#
# Values are checked for formatting and exclusion from a list of reserved path
# names.
class NamespaceValidator < ActiveModel::EachValidator
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

  STRICT_RESERVED = (RESERVED + WILDCARD_ROUTES).freeze

  def self.valid?(value)
    !reserved?(value) && follow_format?(value)
  end

  def self.reserved?(value, strict: false)
    if strict
      STRICT_RESERVED.include?(value)
    else
      RESERVED.include?(value)
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

    strict = record.is_a?(Group) && record.parent_id

    if reserved?(value, strict: strict)
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end
end
