class RemoveNotificationSettingNotNullConstraints < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column :notification_settings, :source_type, :string, null: true
    change_column :notification_settings, :source_id, :integer, null: true
  end

  def down
    # no-op since the data would prevent the change of the null constraint
  end
end
