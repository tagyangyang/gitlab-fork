# rubocop:disable all
class MergeRequestErrorField < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :merge_requests, :merge_error, :string
  end
end
