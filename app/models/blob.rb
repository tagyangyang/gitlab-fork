# Blob is a Rails-specific wrapper around Gitlab::Git::Blob objects
class Blob < SimpleDelegator
  CACHE_TIME = 60 # Cache raw blobs referred to by a (mutable) ref for 1 minute
  CACHE_TIME_IMMUTABLE = 3600 # Cache blobs referred to by an immutable reference for 1 hour

  MAXIMUM_TEXT_HIGHLIGHT_SIZE = 1.megabyte

  RICH_VIEWERS = [
    BlobViewer::Image,
    BlobViewer::Video,
    BlobViewer::PDF,
    BlobViewer::Sketch,
    BlobViewer::BinarySTL,
    BlobViewer::TextSTL,
    BlobViewer::Notebook,
    BlobViewer::SVG,
    BlobViewer::Markup,
  ].freeze

  attr_reader :project

  # Wrap a Gitlab::Git::Blob object, or return nil when given nil
  #
  # This method prevents the decorated object from evaluating to "truthy" when
  # given a nil value. For example:
  #
  #     blob = Blob.new(nil)
  #     puts "truthy" if blob # => "truthy"
  #
  #     blob = Blob.decorate(nil)
  #     puts "truthy" if blob # No output
  def self.decorate(blob, project)
    return if blob.nil?

    new(blob, project)
  end

  def initialize(blob, project)
    @project = project

    super(blob)
  end

  # Returns the data of the blob.
  #
  # If the blob is a text based blob the content is converted to UTF-8 and any
  # invalid byte sequences are replaced.
  def data
    if binary?
      super
    else
      @data ||= super.encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
    end
  end

  def no_highlighting?
    size && size > MAXIMUM_TEXT_HIGHLIGHT_SIZE
  end

  def too_large?
    size && truncated?
  end

  def raw_size
    if valid_lfs_pointer?
      lfs_size
    else
      size
    end
  end

  def extension
    @extension ||= extname.downcase.delete('.')
  end

  def video?
    UploaderHelper::VIDEO_EXT.include?(extension)
  end

  def readable_text?
    text? && !valid_lfs_pointer? && !too_large?
  end

  def valid_lfs_pointer?
    lfs_pointer? && project.lfs_enabled?
  end

  def invalid_lfs_pointer?
    lfs_pointer? && !project.lfs_enabled?
  end

  def simple_viewer
    @simple_viewer ||=
      if empty?
        BlobViewer::Empty
      elsif rich_viewer&.text_based?
        BlobViewer::Text
      elsif binary? || valid_lfs_pointer?
        BlobViewer::Download
      else # text
        BlobViewer::Text
      end
  end

  def rendered_as_text?
    simple_viewer.text_based? && !simple_viewer.render_error(self)
  end

  def rich_viewer
    return @rich_viewer if defined?(@rich_viewer)

    @rich_viewer ||=
      if invalid_lfs_pointer? || empty?
        nil
      else
        rich_viewers.find { |viewer| viewer.supports?(self) }
      end
  end

  private

  def rich_viewers
    if valid_lfs_pointer?
      RICH_VIEWERS
    elsif binary?
      RICH_VIEWERS.reject(&:text_based?)
    else # text
      RICH_VIEWERS.select(&:text_based?)
    end
  end
end
