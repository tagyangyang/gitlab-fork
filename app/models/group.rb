require 'carrierwave/orm/activerecord'

class Group < Namespace
  include Gitlab::ConfigHelper
  include Gitlab::VisibilityLevel
  include AccessRequestable
  include Referable
  include SelectForProjectAuthorization

  has_many :group_members, -> { where(requested_at: nil) }, dependent: :destroy, as: :source
  alias_method :members, :group_members
  has_many :users, through: :group_members
  has_many :owners,
    -> { where(members: { access_level: Gitlab::Access::OWNER }) },
    through: :group_members,
    source: :user

  has_many :requesters, -> { where.not(requested_at: nil) }, dependent: :destroy, as: :source, class_name: 'GroupMember'

  has_many :project_group_links, dependent: :destroy
  has_many :shared_projects, through: :project_group_links, source: :project
  has_many :notification_settings, dependent: :destroy, as: :source
  has_many :labels, class_name: 'GroupLabel'

  validate :avatar_type, if: ->(user) { user.avatar.present? && user.avatar_changed? }
  validate :visibility_level_allowed_by_projects

  validates :avatar, file_size: { maximum: 200.kilobytes.to_i }

  validates :two_factor_grace_period, presence: true, numericality: { greater_than_or_equal_to: 0 }

  mount_uploader :avatar, AvatarUploader
  has_many :uploads, as: :model, dependent: :destroy

  after_create :post_create_hook
  after_destroy :post_destroy_hook
  after_save :update_two_factor_requirement

  class << self
    # Searches for groups matching the given query.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query - The search query as a String
    #
    # Returns an ActiveRecord::Relation.
    def search(query)
      table   = Namespace.arel_table
      pattern = "%#{query}%"

      where(table[:name].matches(pattern).or(table[:path].matches(pattern)))
    end

    def sort(method)
      if method == 'storage_size_desc'
        # storage_size is a virtual column so we need to
        # pass a string to avoid AR adding the table name
        reorder('storage_size DESC, namespaces.id DESC')
      else
        order_by(method)
      end
    end

    def reference_prefix
      User.reference_prefix
    end

    def reference_pattern
      User.reference_pattern
    end

    def visible_to_user(user)
      where(id: user.authorized_groups.select(:id).reorder(nil))
    end

    def select_for_project_authorization
      if current_scope.joins_values.include?(:shared_projects)
        joins('INNER JOIN namespaces project_namespace ON project_namespace.id = projects.namespace_id')
          .where('project_namespace.share_with_group_lock = ?',  false)
          .select("members.user_id, projects.id AS project_id, LEAST(project_group_links.group_access, members.access_level) AS access_level")
      else
        super
      end
    end
  end

  def to_reference(_from_project = nil, full: nil)
    "#{self.class.reference_prefix}#{full_path}"
  end

  def web_url
    Gitlab::Routing.url_helpers.group_canonical_url(self)
  end

  def human_name
    full_name
  end

  def visibility_level_field
    :visibility_level
  end

  def visibility_level_allowed_by_projects
    allowed_by_projects = self.projects.where('visibility_level > ?', self.visibility_level).none?

    unless allowed_by_projects
      level_name = Gitlab::VisibilityLevel.level_name(visibility_level).downcase
      self.errors.add(:visibility_level, "#{level_name} is not allowed since there are projects with higher visibility.")
    end

    allowed_by_projects
  end

  def avatar_url(size = nil)
    if self[:avatar].present?
      [gitlab_config.url, avatar.url].join
    end
  end

  def lfs_enabled?
    return false unless Gitlab.config.lfs.enabled
    return Gitlab.config.lfs.enabled if self[:lfs_enabled].nil?

    self[:lfs_enabled]
  end

  def add_users(users, access_level, current_user: nil, expires_at: nil)
    GroupMember.add_users_to_group(
      self,
      users,
      access_level,
      current_user: current_user,
      expires_at: expires_at
    )
  end

  def add_user(user, access_level, current_user: nil, expires_at: nil)
    GroupMember.add_user(
      self,
      user,
      access_level,
      current_user: current_user,
      expires_at: expires_at
    )
  end

  def add_guest(user, current_user = nil)
    add_user(user, :guest, current_user: current_user)
  end

  def add_reporter(user, current_user = nil)
    add_user(user, :reporter, current_user: current_user)
  end

  def add_developer(user, current_user = nil)
    add_user(user, :developer, current_user: current_user)
  end

  def add_master(user, current_user = nil)
    add_user(user, :master, current_user: current_user)
  end

  def add_owner(user, current_user = nil)
    add_user(user, :owner, current_user: current_user)
  end

  def has_owner?(user)
    members_with_parents.owners.where(user_id: user).any?
  end

  def has_master?(user)
    members_with_parents.masters.where(user_id: user).any?
  end

  # Check if user is a last owner of the group.
  # Parent owners are ignored for nested groups.
  def last_owner?(user)
    owners.include?(user) && owners.size == 1
  end

  def avatar_type
    unless self.avatar.image?
      self.errors.add :avatar, "only images allowed"
    end
  end

  def post_create_hook
    Gitlab::AppLogger.info("Group \"#{name}\" was created")

    system_hook_service.execute_hooks_for(self, :create)
  end

  def post_destroy_hook
    Gitlab::AppLogger.info("Group \"#{name}\" was removed")

    system_hook_service.execute_hooks_for(self, :destroy)
  end

  def system_hook_service
    SystemHooksService.new
  end

  def refresh_members_authorized_projects
    UserProjectAccessChangedService.new(user_ids_for_project_authorizations).
      execute
  end

  def user_ids_for_project_authorizations
    users_with_parents.pluck(:id)
  end

  def members_with_parents
    GroupMember.non_request.where(source_id: ancestors.pluck(:id).push(id))
  end

  def users_with_parents
    User.where(id: members_with_parents.select(:user_id))
  end

  def mattermost_team_params
    max_length = 59

    {
      name: path[0..max_length],
      display_name: name[0..max_length],
      type: public? ? 'O' : 'I' # Open vs Invite-only
    }
  end

  protected

  def update_two_factor_requirement
    return unless require_two_factor_authentication_changed? || two_factor_grace_period_changed?

    users.find_each(&:update_two_factor_requirement)
  end
end
