module Gitlab
  module DependencyLinker
    class JsonLinker < BaseLinker
      def link
        return highlighted_text unless json

        super
      end

      private

      def json
        @json ||= JSON.parse(plain_text) rescue nil
      end
    end
  end
end
