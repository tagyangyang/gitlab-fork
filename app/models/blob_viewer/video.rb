module BlobViewer
  class Video < Rich
    def self.partial_name
      'video'
    end

    def self.extensions
      UploaderHelper::VIDEO_EXT
    end

    def self.text_based?
      false
    end
  end
end
