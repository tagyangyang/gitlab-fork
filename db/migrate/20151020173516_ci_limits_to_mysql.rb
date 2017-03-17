# rubocop:disable all
class CiLimitsToMysql < ActiveRecord::Migration
  DOWNTIME = false

  def up
    return unless Gitlab::Database.mysql?

    # CI
    change_column :ci_builds, :trace, :text, limit: 1073741823
    change_column :ci_commits, :push_data, :text, limit: 16777215
  end

  def down
    return unless Gitlab::Database.mysql?

    # no-op, keep the new limit to prevent data loss
  end
end
