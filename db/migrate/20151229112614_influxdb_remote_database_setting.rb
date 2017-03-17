# rubocop:disable all
class InfluxdbRemoteDatabaseSetting < ActiveRecord::Migration
  DOWNTIME = false

  def change
    remove_column :application_settings, :metrics_database, :string
  end
end
