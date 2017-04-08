module BlobViewer
  class Simple < Base
    def self.client_side?
      false
    end

    def self.type
      :simple
    end
  end
end
