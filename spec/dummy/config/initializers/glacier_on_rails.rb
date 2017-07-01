require 'glacier_on_rails/config'
GlacierOnRails::Config.setup do |config|
  config.attached_files_directory = FileUploadLocation.join('store')
  config.orphan_files_directory = FileUploadLocation.join( "..", "orphan_files")
end
