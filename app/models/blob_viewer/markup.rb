module BlobViewer
  class Markup < Rich
    def self.partial_name
      'markup'
    end

    def self.extensions
      Gitlab::MarkupHelper::EXTENSIONS
    end

    def self.client_side?
      false
    end

    def self.text_based?
      true
    end
  end
end
