# rubocop:disable all
class AddIndexToCiTables < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_index :ci_builds, :gl_project_id
    add_index :ci_runner_projects, :gl_project_id
    add_index :ci_triggers, :gl_project_id
    add_index :ci_variables, :gl_project_id
    add_index :projects, :runners_token
    add_index :projects, :builds_enabled
    add_index :projects, [:builds_enabled, :shared_runners_enabled]
    add_index :projects, [:ci_id]
  end

  def down
    remove_index :ci_builds, :gl_project_id if index_exists?(:ci_builds, :gl_project_id)
    remove_index :ci_runner_projects, :gl_project_id if index_exists?(:ci_runner_projects, :gl_project_id)
    remove_index :ci_triggers, :gl_project_id if index_exists?(:ci_triggers, :gl_project_id)
    remove_index :ci_variables, :gl_project_id if index_exists?(:ci_variables, :gl_project_id)
    remove_index :projects, :runners_token if index_exists?(:projects, :runners_token)
    remove_index :projects, :builds_enabled if index_exists?(:projects, :builds_enabled)
    remove_index :projects, [:builds_enabled, :shared_runners_enabled] if index_exists?(:projects, [:builds_enabled, :shared_runners_enabled])
    remove_index :projects, [:ci_id] if index_exists?(:projects, [:ci_id])
  end
end
