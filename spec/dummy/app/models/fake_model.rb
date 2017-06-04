class FakeModel < ApplicationRecord
  FilePath = GetBack::Config.attached_files_directory
  after_create do |fake_model|
    FileUtils.touch FilePath.join(fake_model.file_id)
  end
end
