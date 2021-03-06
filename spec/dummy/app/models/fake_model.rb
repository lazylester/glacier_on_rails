class FakeModel < ApplicationRecord
  FilePath = GlacierOnRails::Config.attached_files_directory
  after_create do |fake_model|
    FileUtils.touch FilePath.join(fake_model.file_id)
  end

  after_destroy do |fake_model|
    FileUtils.rm FilePath.join(fake_model.file_id)
  end
end
