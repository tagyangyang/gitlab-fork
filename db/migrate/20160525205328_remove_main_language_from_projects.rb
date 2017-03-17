# rubocop:disable all
class RemoveMainLanguageFromProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    remove_column :projects, :main_language, :string
  end
end
