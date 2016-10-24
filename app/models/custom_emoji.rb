class CustomEmoji < ActiveRecord::Base
  belongs_to :project

  validates :name, presence: true, format: /\A\w+\z/, uniqueness: { scope: :project_id }
  validates :emoji, presence: true, file_size: { maximum: 256.kilobytes.to_i }
  validate :emoji_type

  mount_uploader :emoji, CustomEmojiUploader

  def emoji_type
    unless emoji.image?
      errors.add(:emoji, 'only images allowed')
    end
  end
end
