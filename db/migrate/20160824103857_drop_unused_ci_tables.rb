class DropUnusedCiTables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    drop_table(:ci_services)
    drop_table(:ci_web_hooks)
  end

  def down
    create_table "ci_web_hooks", force: true do |t|
      t.string   "url",        null: false
      t.integer  "project_id", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "ci_services", force: true do |t|
      t.string   "type"
      t.string   "title"
      t.integer  "project_id",                 null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "active",     default: false, null: false
      t.text     "properties"
    end
  end
end
