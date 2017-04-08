# Blob is a Rails-specific wrapper around Gitlab::Git::Blob objects
class Blob < SimpleDelegator
  CACHE_TIME = 60 # Cache raw blobs referred to by a (mutable) ref for 1 minute
  CACHE_TIME_IMMUTABLE = 3600 # Cache blobs referred to by an immutable reference for 1 hour

  # The maximum size of an SVG that can be displayed.
  MAXIMUM_SVG_SIZE = 2.megabytes

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
  def self.decorate(blob)
    return if blob.nil?

    new(blob)
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
    size && size > 1.megabyte
  end

  def only_display_raw?
    size && truncated?
  end

  def extension
    extname.downcase.delete('.')
  end

  def svg?
    text? && language && language.name == 'SVG'
  end

  def pdf?
    extension == 'pdf'
  end

  def ipython_notebook?
    text? && language&.name == 'Jupyter Notebook'
  end

  def sketch?
    binary? && extension == 'sketch'
  end

  def stl?
    extension == 'stl'
  end

  def markup?
    text? && Gitlab::MarkupHelper.markup?(name)
  end

  def size_within_svg_limits?
    size <= MAXIMUM_SVG_SIZE
  end

  def video?
    UploaderHelper::VIDEO_EXT.include?(extname.downcase.delete('.'))
  end

  def to_partial_path(project)
    if lfs_pointer?
      if project.lfs_enabled?
        'download'
      else
        'text'
      end
    elsif image?
      'image'
    elsif svg?
      'svg'
    elsif pdf?
      'pdf'
    elsif ipython_notebook?
      'notebook'
    elsif sketch?
      'sketch'
    elsif stl?
      'stl'
    elsif markup?
      if only_display_raw?
        'too_large'
      else
        'markup'
      end
    elsif text?
      if only_display_raw?
        'too_large'
      else
        'text'
      end
    else
      'download'
    end
  end
end
