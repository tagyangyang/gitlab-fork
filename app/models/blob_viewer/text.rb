module BlobViewer
  class Text < Simple
    def self.partial_name
      'text'
    end

    def self.text_based?
      true
    end
  end
end
