module Gitlab
  module Email
    class HTMLParser
      def self.parse_reply(raw_body)
        new(raw_body).filtered_text
      end

      attr_reader :raw_body
      def initialize(raw_body)
        @raw_body = raw_body
      end

      def document
        @document ||= Nokogiri::HTML.parse(raw_body)
      end

      def filter_replies!
        document.xpath('//blockquote').each(&:remove)
        document.xpath('//table').each(&:remove)

        # these bogus links are added by outlook, and can
        # result in extra square brackets being added to the text
        document.xpath('//a[@name="_MailEndCompose"]').each do |link|
          link.replace(link.children)
        end
      end

      def filtered_html
        @filtered_html ||= begin
          filter_replies!
          document.inner_html
        end
      end

      def filtered_text
        @filtered_text ||= Html2Text.convert(filtered_html)
      end
    end
  end
end
