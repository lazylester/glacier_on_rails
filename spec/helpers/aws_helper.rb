require 'rspec/core/shared_context'

module AwsHelper
  extend RSpec::Core::SharedContext

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
    filepath = archive.local_filepath
    system("pg_dump -w -Fc get_back_test > #{filepath}")
  end
end
