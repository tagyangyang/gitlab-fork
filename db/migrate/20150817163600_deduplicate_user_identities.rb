# rubocop:disable all
class DeduplicateUserIdentities < ActiveRecord::Migration
  DOWNTIME = false

  def up
    execute 'DROP TABLE IF EXISTS tt_migration_DeduplicateUserIdentities;'
    execute 'CREATE TABLE tt_migration_DeduplicateUserIdentities AS SELECT id,provider,user_id FROM identities;'
    execute 'DELETE FROM identities WHERE id NOT IN ( SELECT MIN(id) FROM tt_migration_DeduplicateUserIdentities GROUP BY user_id, provider);'
    execute 'DROP TABLE IF EXISTS tt_migration_DeduplicateUserIdentities;'
  end

  def down
    # This is an irreversible migration;
  end
end
