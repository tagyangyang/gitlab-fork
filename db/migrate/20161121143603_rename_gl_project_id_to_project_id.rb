class RenameGlProjectIdToProjectId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'Renaming an actively used column.'

  def up
    rename_column :ci_builds, :gl_project_id, :project_id
    rename_column :ci_commits, :gl_project_id, :project_id
    rename_column :ci_runner_projects, :gl_project_id, :project_id
    rename_column :ci_triggers, :gl_project_id, :project_id
    rename_column :ci_variables, :gl_project_id, :project_id
  end

  def down
    rename_column :ci_builds, :project_id, :gl_project_id
    rename_column :ci_commits, :project_id, :gl_project_id
    rename_column :ci_runner_projects, :project_id, :gl_project_id
    rename_column :ci_triggers, :project_id, :gl_project_id
    rename_column :ci_variables, :project_id, :gl_project_id
  end
end
