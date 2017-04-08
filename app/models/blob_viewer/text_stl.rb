module BlobViewer
  class TextSTL < Rich
    def self.partial_name
      'stl'
    end

    def self.extensions
      %w(stl)
    end

    def self.text_based?
      true
    end
  end
end
