class GroupsFinder < UnionFinder
  def execute(current_user = nil)
    segments = all_groups(current_user)

    find_union(segments, Group).order_id_desc
  end

  private

  def all_groups(current_user)
    return [Group.all] if current_user && current_user.auditor?

    groups = []
    groups << current_user.authorized_groups if current_user
    groups << Group.unscoped.public_to_user(current_user)

    groups
  end
end
