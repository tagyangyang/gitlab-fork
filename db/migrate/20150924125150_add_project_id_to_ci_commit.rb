# rubocop:disable all
class AddProjectIdToCiCommit < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :ci_commits, :gl_project_id, :integer
  end
end
