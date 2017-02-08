module Gitlab
  class AwardEmoji
    CATEGORIES = {
      objects: "Objects",
      travel: "Travel",
      symbols: "Symbols",
      nature: "Nature",
      people: "People",
      activity: "Activity",
      flags: "Flags",
      food: "Food"
    }.with_indifferent_access

    def self.normalize_emoji_name(name)
      aliases[name] || name
    end

    def self.emoji_by_category
      unless @emoji_by_category
        @emoji_by_category = Hash.new { |h, key| h[key] = [] }

        emojis.each do |emoji_name, data|
          data["name"] = emoji_name

          # Skip Fitzpatrick(tone) modifiers
          next if data["category"] == "modifier"

          category = data["category"]

          @emoji_by_category[category] << data
        end

        @emoji_by_category = @emoji_by_category.sort.to_h
      end

      @emoji_by_category
    end

    def self.emojis
      @emojis ||=
        begin
          json_path = File.join(Rails.root, 'fixtures', 'emojis', 'index.json' )
          JSON.parse(File.read(json_path))
        end
    end

    def self.aliases
      @aliases ||=
        begin
          json_path = File.join(Rails.root, 'fixtures', 'emojis', 'aliases.json')
          JSON.parse(File.read(json_path))
        end
    end

    # Returns an Array of Emoji names and their asset URLs.
    def self.urls
      @urls ||= begin
                  path = File.join(Rails.root, 'fixtures', 'emojis', 'digests.json')

                  JSON.parse(File.read(path)).map do |hash|
                    { name: hash['name'], path: hash['fallbackImageSrc'], moji: hash['moji'], unicode_version: hash['unicodeVersion'] }
                  end
                end
    end
  end
end
