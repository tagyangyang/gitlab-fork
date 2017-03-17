# rubocop:disable all
class SetTypeOnLegacyDiffNotes < ActiveRecord::Migration
  DOWNTIME = false

  def up
    execute "UPDATE notes SET type = 'LegacyDiffNote' WHERE line_code IS NOT NULL"
  end

  def down
    # no-op
  end
end
