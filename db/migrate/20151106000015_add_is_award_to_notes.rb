# rubocop:disable all
class AddIsAwardToNotes < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_column :notes, :is_award, :boolean, default: false, null: false
    add_index :notes, :is_award
  end

  def down
    remove_column :notes, :is_award
    # This one is removed in ConvertAwardNoteToEmojiAward
    remove_index :notes, column: :is_award if index_exists?(:notes, :is_award)
  end
end
