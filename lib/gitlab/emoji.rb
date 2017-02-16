module Gitlab
  module Emoji
    extend self
    @emoji_unicode_version = JSON.parse(File.read(File.absolute_path(File.dirname(__FILE__) + '/../../node_modules/emoji-unicode-version/emoji-unicode-version-map.json')))

    def emojis
      Gemojione.index.instance_variable_get(:@emoji_by_name)
    end

    def emojis_by_moji
      Gemojione.index.instance_variable_get(:@emoji_by_moji)
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

    def emoji_unicode_version(name)
      @emoji_unicode_version[name]
    end

    def emoji_image_tag(name, src)
      "<img class='emoji' title=':#{name}:' alt=':#{name}:' src='#{src}' height='20' width='20' align='absmiddle' />"
    end

    # CSS sprite fallback takes precedence over image fallback
    def gl_emoji_tag(name, fallback_image_source: nil, sprite: false, force_fallback: false)
      emoji_info = emojis[name]
      emoji_fallback_image_source = fallback_image_source || ActionController::Base.helpers.url_to_image("#{emoji_info['unicode']}.png")
      emoji_fallback_css_class = "emoji-#{emoji_info['unicode']}"
      "<gl-emoji #{force_fallback && sprite ? "class='emoji-icon #{emoji_fallback_css_class}'" : ""} data-name='#{name}' data-fallback-src='#{emoji_fallback_image_source}' #{sprite ? "data-fallback-css-class='#{emoji_fallback_css_class}'" : ""} data-unicode-version='#{emoji_unicode_version(name)}'>#{force_fallback && sprite === false ? emoji_image_tag(name, emoji_fallback_image_source) : emoji_info['moji']}</gl-emoji>"
    end
  end
end
