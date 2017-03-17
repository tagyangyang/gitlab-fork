# rubocop:disable all
class IndexNamespacesOnVisibilityLevel < ActiveRecord::Migration
  DOWNTIME = false

  def up
    unless index_exists?(:namespaces, :visibility_level)
      add_index :namespaces, :visibility_level
    end
  end

  def down
    if index_exists?(:namespaces, :visibility_level)
      add_index :namespaces, :visibility_level
    end
  end
end
