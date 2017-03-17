# rubocop:disable all
class AddIndexToCreatedAt < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_index "users", [:created_at, :id]
    add_index "members", [:created_at, :id]
    add_index "projects", [:created_at, :id]
    add_index "issues", [:created_at, :id]
    add_index "merge_requests", [:created_at, :id]
    add_index "milestones", [:created_at, :id]
    add_index "namespaces", [:created_at, :id]
    add_index "notes", [:created_at, :id]
    add_index "identities", [:created_at, :id]
    add_index "keys", [:created_at, :id]
    add_index "web_hooks", [:created_at, :id]
    add_index "snippets", [:created_at, :id]
  end

  def down
    # These one is removed by RemoveRedundantIndexes
    remove_index :snippets, column: [:created_at, :id] if index_exists?(:snippets, [:created_at, :id])
    remove_index :web_hooks, column: [:created_at, :id] if index_exists?(:web_hooks, [:created_at, :id])
    remove_index :keys, column: [:created_at, :id] if index_exists?(:keys, [:created_at, :id])
    remove_index :identities, column: [:created_at, :id] if index_exists?(:identities, [:created_at, :id])
    remove_index :notes, column: [:created_at, :id] if index_exists?(:notes, [:created_at, :id])
    remove_index :namespaces, column: [:created_at, :id] if index_exists?(:namespaces, [:created_at, :id])
    remove_index :milestones, column: [:created_at, :id] if index_exists?(:milestones, [:created_at, :id])
    remove_index :merge_requests, column: [:created_at, :id] if index_exists?(:merge_requests, [:created_at, :id])
    remove_index :issues, column: [:created_at, :id] if index_exists?(:issues, [:created_at, :id])
    remove_index :projects, column: [:created_at, :id] if index_exists?(:projects, [:created_at, :id])
    remove_index :members, column: [:created_at, :id] if index_exists?(:members, [:created_at, :id])
    remove_index :users, column: [:created_at, :id] if index_exists?(:users, [:created_at, :id])
  end
end
