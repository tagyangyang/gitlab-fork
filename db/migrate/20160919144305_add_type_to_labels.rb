class AddTypeToLabels < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'Labels will not work as expected until this migration is complete.'

  def up
    add_column :labels, :type, :string

    update_column_in_batches(:labels, :type, 'ProjectLabel') do |table, query|
      query.where(table[:project_id].not_eq(nil))
    end
  end

  def down
    remove_column :labels, :type
  end
end
