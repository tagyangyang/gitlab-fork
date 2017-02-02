module Gitlab
  module Emoji
    extend self
    @emoji_list = JSON.parse(File.read(File.absolute_path(File.dirname(__FILE__) + '/../../fixtures/emojis/index.json')))
    @gemojione = Gemojione::Index.new(@emoji_list)

    def emojis
      @gemojione.instance_variable_get(:@emoji_by_name)
    end

    def emojis_by_moji
      @gemojione.instance_variable_get(:@emoji_by_moji)
    end

    def emojis_unicodes
      emojis_by_moji.keys
    end

    def emojis_names
      emojis.keys
    end

    def emoji_filename(name)
      emojis[name]["unicode"]
    end

    def emoji_unicode_filename(moji)
      emojis_by_moji[moji]["unicode"]
    end
  end
end
