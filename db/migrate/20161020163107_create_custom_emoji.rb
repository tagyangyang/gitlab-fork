class CreateCustomEmoji < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :custom_emoji do |t|
      t.references :project, index: true, foreign_key: true, null: false
      t.string :name
      t.string :emoji

      t.timestamps null: false
    end

    add_index :custom_emoji, [:project_id, :name], unique: true
  end
end
