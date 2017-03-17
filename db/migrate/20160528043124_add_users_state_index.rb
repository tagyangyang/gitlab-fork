# rubocop:disable all
class AddUsersStateIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_concurrent_index :users, :state
  end

  def down
    remove_index :users, :state
  end
end
