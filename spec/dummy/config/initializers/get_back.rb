require 'get_back/config'
GetBack::Config.setup do |config|
  config.attached_files_directory = FileUploadLocation.join('store')
end
