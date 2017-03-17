# rubocop:disable all
# Migration type: online without errors

class AddIndexOnAwardEmojiUserAndName < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_concurrent_index(:award_emoji, [:user_id, :name])
  end

  def down
    remove_index :award_emoji, [:user_id, :name]
  end
end
