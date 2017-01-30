module Gitlab
  class AwardEmoji
    def self.normalize_emoji_name(name)
      aliases[name] || name
    end

    def self.emojis
      Gitlab::Emoji.emojis
    end

    def self.aliases
      @aliases ||=
        begin
          json_path = File.join(Rails.root, 'fixtures', 'emojis', 'aliases.json')
          JSON.parse(File.read(json_path))
        end
    end
  end
end
