# rubocop:disable all
class AddUniqueForLfsOidIndex < ActiveRecord::Migration
  DOWNTIME = false

  def change
    remove_index :lfs_objects, column: :oid
    remove_index :lfs_objects, column: [:oid, :size]
    add_index :lfs_objects, :oid, unique: true
  end
end
