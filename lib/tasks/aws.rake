namespace :aws do
  desc "create and save to aws glacier a copy of the postgres database"
  task :create_db_archive => :environment do
    puts "#{Time.now} create db archive"
    ApplicationDataBackup.create
  end
end
