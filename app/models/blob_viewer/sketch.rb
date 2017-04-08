module BlobViewer
  class Sketch < Rich
    def self.partial_name
      'sketch'
    end

    def self.extensions
      %w(sketch)
    end

    def self.text_based?
      false
    end
  end
end
