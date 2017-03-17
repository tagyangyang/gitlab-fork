# rubocop:disable all
class AllowNullInServicesProjectId < ActiveRecord::Migration
  DOWNTIME = false

  def up
    change_column :services, :project_id, :integer, null: true
  end

  def down
    change_column :services, :project_id, :integer, null: false
  end
end
