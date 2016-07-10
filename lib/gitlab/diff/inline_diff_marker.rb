module Gitlab
  module Diff
    class InlineDiffMarker < Gitlab::StringRangeMarker
      MARKDOWN_SYMBOLS = {
        addition: "+",
        deletion: "-"
      }

      def mark(line_inline_diffs, mode: nil, markdown: false)
        super(line_inline_diffs) do |text, left:, right:|
          before_content =
            if markdown
              "{#{MARKDOWN_SYMBOLS[mode]}"
            else
              "<span class='#{html_class_names(left, right, mode)}'>"
            end
          after_content =
            if markdown
              "#{MARKDOWN_SYMBOLS[mode]}}"
            else
              "</span>"
            end

          "#{before_content}#{text}#{after_content}"
        end
      end

      private

      def html_class_names(left, right, mode)
        class_names = ["idiff"]
        class_names << "left"  if left
        class_names << "right" if right
        class_names << mode if mode
        class_names.join(" ")
      end
    end
  end
end
