module BlobViewer
  class Base
    def self.partial_name
      raise NotImplementedError
    end

    def self.partial_path
      "projects/blob/viewers/#{partial_name}"
    end

    def self.type
      raise NotImplementedError
    end

    def self.rich?
      type == :rich
    end

    def self.simple?
      type == :simple
    end

    def self.client_side?
      raise NotImplementedError
    end

    def self.extensions
      nil
    end

    def self.text_based?
      false
    end

    def self.max_size
      Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE
    end

    def self.supports?(blob)
      supports = true

      if extensions
        supports &&= extensions.include?(blob.extension)
      end

      supports
    end

    def self.render_error(blob)
      if max_size && blob.raw_size > max_size
        :too_large
      elsif !client_side? && blob.valid_lfs_pointer?
        :server_side_but_stored_in_lfs
      end
    end
  end
end
