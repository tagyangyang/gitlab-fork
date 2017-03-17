# rubocop:disable all
class AddProjectsPublicIndex < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_index :namespaces, :public
  end

  def change
    # This one is removed in RemovePublicFromNamespace
    remove_index :namespaces, :public if index_exists?(:namespaces, :public)
  end
end
