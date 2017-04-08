module BlobViewer
  class PDF < Rich
    def self.partial_name
      'pdf'
    end

    def self.extensions
      %w(pdf)
    end

    def self.text_based?
      false
    end
  end
end
