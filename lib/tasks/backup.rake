require 'find'
require 'fileutils'

namespace :db do
  desc "Backup the database to a file. Options: RAILS_ENV=production MAX=5. Deletes any backup files in excess of MAX" 
  task :backup => :environment do
    backup = BackupFile.new
    backup.save
    puts "Created backup: #{backup.date}"

    max_backups = (ENV["MAX"] || 5).to_i

    to_be_deleted = BackupFile.excess_above(max_backups)
    to_be_deleted.each do |bf|
      puts "Deleting backup #{bf.date}"
      bf.destroy
    end unless to_be_deleted.nil?
  end

  desc "take a snapshot of the current database contents and save in the tmp directory"
  task :snapshot do
    snapshot = BackupFile.new(:dir => 'tmp')
    snapshot.save
  end

  desc "restores the database from the most recent backup"
  task :restore do
    ApplicationDatabase.restore_from_zipfile BackupFile.most_recent
  end
end
