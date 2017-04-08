module BlobViewer
  class SVG < Rich
    def self.partial_name
      'svg'
    end

    def self.extensions
      %w(svg)
    end

    def self.client_side?
      false
    end

    def self.text_based?
      true
    end

    def self.max_size
      2.megabytes
    end
  end
end
