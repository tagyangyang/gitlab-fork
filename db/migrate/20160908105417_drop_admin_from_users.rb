# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropAdminFromUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_column :users, :admin
  end

  def down
    add_column_with_default(:users, :admin, :boolean, default: false)
    add_concurrent_index :users, [:admin], { name: "index_users_on_admin", using: :btree }
  end
end
