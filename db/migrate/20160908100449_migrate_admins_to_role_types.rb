# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateAdminsToRoleTypes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sql =
      %Q{
        UPDATE users
        SET
        role_type = 1
        WHERE admin = TRUE
      }

    execute(sql)
  end

  def down
    sql =
      %Q{
        UPDATE users
        SET
        admin = TRUE
        WHERE role_type = 1
      }

    execute(sql)
  end
end
