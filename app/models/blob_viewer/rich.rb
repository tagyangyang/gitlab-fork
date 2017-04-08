module BlobViewer
  class Rich < Base
    def self.client_side?
      true
    end

    def self.type
      :rich
    end
  end
end
