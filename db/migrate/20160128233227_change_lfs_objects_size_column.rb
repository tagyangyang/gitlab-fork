# rubocop:disable all
class ChangeLfsObjectsSizeColumn < ActiveRecord::Migration
  DOWNTIME = false

  def up
    change_column :lfs_objects, :size, :integer, limit: 8
  end

  def down
    # no-op, keep the new limit to prevent data loss
  end
end
