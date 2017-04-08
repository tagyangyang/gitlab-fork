module BlobViewer
  class Notebook < Rich
    def self.partial_name
      'notebook'
    end

    def self.extensions
      %w(ipynb)
    end

    def self.text_based?
      true
    end
  end
end
