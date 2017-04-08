module BlobViewer
  class Download < Simple
    def self.partial_name
      'download'
    end

    def self.render_error(blob)
      nil
    end
  end
end
