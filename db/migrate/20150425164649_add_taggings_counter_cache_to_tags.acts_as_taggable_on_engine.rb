# rubocop:disable all
# This migration comes from acts_as_taggable_on_engine (originally 3)
class AddTaggingsCounterCacheToTags < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_column :tags, :taggings_count, :integer, default: 0

    return unless ActsAsTaggableOn.tags_counter

    ActsAsTaggableOn::Tag.reset_column_information
    ActsAsTaggableOn::Tag.find_each do |tag|
      ActsAsTaggableOn::Tag.reset_counters(tag.id, :taggings)
    end
  end

  def down
    remove_column :tags, :taggings_count
  end
end
