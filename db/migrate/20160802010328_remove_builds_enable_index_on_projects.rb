# rubocop:disable RemoveIndex
# rubocop:disable AddIndex
class RemoveBuildsEnableIndexOnProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    remove_index :projects, :builds_enabled if index_exists?(:projects, :builds_enabled)
  end

  def down
    add_index :projects, :builds_enabled unless index_exists?(:projects, :builds_enabled)
  end
end
