class ChangeMergeErrorToText < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'This migration requires downtime because it alters a column from varchar(255) to text.'

  def up
    change_column :merge_requests, :merge_error, :text, limit: 65535
  end

  def down
    change_column :merge_requests, :merge_error, :string
  end
end
