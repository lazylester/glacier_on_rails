desc "Send email with daily backup"
task :email_backup => "db:backup" do
  puts "sending backup file by email"
  backfile = BackupFile.most_recent
  BackupMailer.backup_file(backfile.gzipped).deliver
end
