# rubocop:disable RemoveIndex
class AddIndexForBuildToken < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_builds, :token, unique: true
  end

  def down
    remove_index :ci_builds, :token if index_exists? :ci_builds, :token, unique: true
  end
end
