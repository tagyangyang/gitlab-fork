# rubocop:disable all
class MigrateNameToDescriptionForBuilds < ActiveRecord::Migration
  DOWNTIME = false

  def up
    execute("UPDATE ci_builds SET type='Ci::Build' WHERE type IS NULL")
  end

  def down
    # no-op
  end
end
