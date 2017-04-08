module BlobViewer
  class BinarySTL < Rich
    def self.partial_name
      'stl'
    end

    def self.extensions
      %w(stl)
    end

    def self.text_based?
      false
    end
  end
end
