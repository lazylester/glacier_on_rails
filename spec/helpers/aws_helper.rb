require 'rspec/core/shared_context'

module AwsHelper
  extend RSpec::Core::SharedContext

  def remove_attached_files_from_filesystem
    # b/c archive files are not retrieved if they exist in the filesystem
    FakeModel.all.each do |fm|
      FileUtils.rm(FakeModel::FilePath.join(fm.file_id))
    end
  end

  def create_application_data_backup_with_local_database_components
    create_glacier_database_archive_with_local_status
    @application_data_backup = ApplicationDataBackup.create(:glacier_file_archives => [],
                                                            :glacier_db_archive => GlacierDbArchive.last)
    File.open GlacierDbArchive.last.backup_file, 'w+' do |file|
      file.write(ApplicationDatabase.new.contents)
    end
  end

  def create_application_data_backup_with_local_components
    ApplicationDataBackup.create
    # Create the backup files as if they were retrieved from AWS:
    File.open GlacierDbArchive.last.backup_file, 'w+' do |file|
      file.write(ApplicationDatabase.new.contents)
    end
    GlacierFileArchive.all.each do |archive|
      FileUtils.touch(archive.backup_file)
    end
  end


  def create_glacier_database_archive_with_local_status
    sql = <<-SQL
    insert into glacier_archives
      ( type, filename, archive_id,created_at,updated_at)
      values ('GlacierDbArchive', '#{Time.now.strftime("%Y_%m_%d_%H_%M_%S_%L.sql")}', 'random_archive_id','#{Time.now}','#{Time.now}');
    SQL
    ActiveRecord::Base.connection.execute(sql)
  end

  def create_application_data_backup_with_ready_and_expired_components
    create_application_data_backup_with_ready_components
    @application_data_backup.glacier_file_archives.first.update_attributes(:archive_retrieval_job_id => "expiredJobId")
  end

  def create_application_data_backup_with_ready_components
    @application_data_backup = ApplicationDataBackup.create
    @application_data_backup.glacier_db_archive.update_attributes(:notification => {"fake_notification" => "nonsense"}, :archive_retrieval_job_id => 'validDbRetrievalJobId')
    @application_data_backup.glacier_file_archives.each do |archive|
      archive.update_attributes(:notification => {"fake_notification" => "nonsense"}, :archive_retrieval_job_id => 'validFileRetrievalJobId')
    end
  end

  def create_application_data_backup_with_available_components
    #create_glacier_archives_with_available_status
    @application_data_backup = ApplicationDataBackup.create
  end

  def create_glacier_archives_with_available_status
    sql = <<-SQL
    insert into glacier_archives
      ( type, filename, archive_id, created_at,updated_at)
      values ('GlacierDbArchive', '#{Time.now.strftime("%Y_%m_%d_%H_%M_%S_%L.sql")}', 'random_archive_id','#{Time.now}','#{Time.now}'),
             ('GlacierFileArchive', '1234abc', 'random_archive_id','#{Time.now}','#{Time.now}'),
             ('GlacierFileArchive', '4567def', 'random_archive_id','#{Time.now}','#{Time.now}'),
             ('GlacierFileArchive', '8899bin', 'random_archive_id','#{Time.now}','#{Time.now}')
    SQL
    ActiveRecord::Base.connection.execute(sql)
  end

  def flash_message
    page.find('#jflash').text
  end

  def aws_log
    File.read(AwsLog::LogFile)
  end

  def delete_database
    ActiveRecord::Base.connection.execute("drop table if exists test;")
  end

  def change_database
    ActiveRecord::Base.connection.execute("update test set foo = 'bosh' where foo = 'bar';")
  end

  def create_compressed_archive(archive)
    sql =<<-SQL
      drop table if exists test;
      create table test ( foo varchar(255));
      insert into test (foo) values ('bar');
    SQL
    ActiveRecord::Base.connection.execute(sql)
    filepath = archive.backup_file
    system("pg_dump -w -Fc glacier_on_rails_test > #{filepath}")
  end
end
