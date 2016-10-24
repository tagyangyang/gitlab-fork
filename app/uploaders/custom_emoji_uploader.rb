class CustomEmojiUploader < CarrierWave::Uploader::Base
  include UploaderHelper

  storage :file

  attr_reader :project, :secret

  def initialize(project, secret = nil)
    @project = project
    @secret = secret
  end



  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def exists?
    model.emoji.file && model.emoji.file.exists?
  end
end
