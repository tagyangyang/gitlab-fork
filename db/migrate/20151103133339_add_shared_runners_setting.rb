# rubocop:disable all
class AddSharedRunnersSetting < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :application_settings, :shared_runners_enabled, :boolean, default: true, null: false
  end
end
