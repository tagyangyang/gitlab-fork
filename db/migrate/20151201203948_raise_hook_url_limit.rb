# rubocop:disable all
class RaiseHookUrlLimit < ActiveRecord::Migration
  DOWNTIME = false

  def up
    change_column :web_hooks, :url, :string, limit: 2000
  end

  def down
    # no-op, keep the new limit to prevent data loss
  end
end
