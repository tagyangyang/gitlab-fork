# rubocop:disable all
class AddIndexForCommittedAtAndId < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_index :ci_commits, [:project_id, :committed_at, :id]
  end

  def down
    # This one is removed by RemoveRedundantIndexes
    if index_exists?(:ci_commits, [:project_id, :committed_at, :id])
      remove_index :ci_commits, column: [:project_id, :committed_at, :id]
    end
  end
end
