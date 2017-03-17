# rubocop:disable all
class MigrateRefAndTagToBuild < ActiveRecord::Migration
  DOWNTIME = false

  def up
    execute('UPDATE ci_builds SET ref=(SELECT ref FROM ci_commits WHERE ci_commits.id = ci_builds.commit_id) WHERE ref IS NULL')
    execute('UPDATE ci_builds SET tag=(SELECT tag FROM ci_commits WHERE ci_commits.id = ci_builds.commit_id) WHERE tag IS NULL')
  end

  def down
    # no-op
  end
end
