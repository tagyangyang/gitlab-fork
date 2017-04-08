module Gitlab
  module MarkupHelper
    extend self

    MARKDOWN_EXTENSIONS = %w(mdown mkd mkdn md markdown).freeze
    ASCIIDOC_EXTENSIONS = %w(adoc ad asciidoc).freeze
    OTHER_EXTENSIONS = %w(textile rdoc org creole wiki mediawiki rst).freeze
    EXTENSIONS = MARKDOWN_EXTENSIONS + ASCIIDOC_EXTENSIONS + OTHER_EXTENSIONS

    # Public: Determines if a given filename is compatible with GitHub::Markup.
    #
    # filename - Filename string to check
    #
    # Returns boolean
    def markup?(filename)
      extension?(filename, EXTENSIONS)
    end

    # Public: Determines if a given filename is compatible with
    # GitLab-flavored Markdown.
    #
    # filename - Filename string to check
    #
    # Returns boolean
    def gitlab_markdown?(filename)
      extension?(filename, MARKDOWN_EXTENSIONS)
    end

    # Public: Determines if the given filename has AsciiDoc extension.
    #
    # filename - Filename string to check
    #
    # Returns boolean
    def asciidoc?(filename)
      extension?(filename, ASCIIDOC_EXTENSIONS)
    end

    # Public: Determines if the given filename is plain text.
    #
    # filename - Filename string to check
    #
    # Returns boolean
    def plain?(filename)
      extension?(filename, %w(txt)) ||
        filename.downcase == 'readme'
    end

    def previewable?(filename)
      markup?(filename)
    end

    private

    def extension?(filename, extensions)
      extensions.include?(File.extname(filename).downcase.delete('.'))
    end
  end
end
