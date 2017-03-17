# rubocop:disable all
class AddCiBuildsAndProjectsIndexes < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_index :ci_projects, :gitlab_id
    add_index :ci_projects, :shared_runners_enabled

    add_index :ci_builds, :type
    add_index :ci_builds, :status
  end

  def down
    # This one is removed by RemoveRedundantIndexes
    remove_index :ci_projects, column: :gitlab_id if index_exists?(:ci_projects, :gitlab_id)
    # This one is removed by RemoveRedundantIndexes
    remove_index :ci_projects, column: :shared_runners_enabled if index_exists?(:ci_projects, :shared_runners_enabled)
    # This one is removed by RemoveRedundantIndexes
    remove_index :ci_builds, column: :type if index_exists?(:ci_builds, :type)
    remove_index :ci_builds, column: :status
  end
end
