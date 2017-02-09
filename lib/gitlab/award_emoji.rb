module Gitlab
  class AwardEmoji
    def self.normalize_emoji_name(name)
      aliases[name] || name
    end

    def self.emojis
      Gitlab::Emoji.emojis
    end
  end
end
