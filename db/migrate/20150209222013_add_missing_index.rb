# rubocop:disable all
class AddMissingIndex < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_index "services", [:created_at, :id]
  end

  def down
    # This one is removed by RemoveRedundantIndexes
    remove_index :services, column: [:created_at, :id] if index_exists?(:services, [:created_at, :id])
  end
end
