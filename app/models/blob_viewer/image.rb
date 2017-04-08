module BlobViewer
  class Image < Rich
    def self.partial_name
      'image'
    end

    def self.extensions
      UploaderHelper::IMAGE_EXT
    end

    def self.text_based?
      false
    end
  end
end
