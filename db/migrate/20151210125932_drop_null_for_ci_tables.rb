# rubocop:disable all
class DropNullForCiTables < ActiveRecord::Migration
  DOWNTIME = false

  def change
    remove_index :ci_variables, column:  :project_id
    remove_index :ci_runner_projects, column:  :project_id
    change_column_null :ci_triggers, :project_id, true
    change_column_null :ci_variables, :project_id, true
    change_column_null :ci_runner_projects, :project_id, true
  end
end
