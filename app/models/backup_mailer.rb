class BackupMailer < ActionMailer::Base
  def backup_file(zipfile)
    recipients  BACKUP_RECIPIENTS
    from        "#{ORGANIZATION_NAME} Database Administrator<#{ADMIN_EMAIL}>"
    headers     "Reply-to" => "#{ADMIN_EMAIL}", "Message-ID"=>"<#{DateTime.now.to_formatted_s(:number)}@#{SITE_URL}>"
    subject     "#{ORGANIZATION_NAME} daily backup file"
    attachment :content_type => "application/x-gzip", :body => zipfile, :filename => DateTime.now.to_formatted_s(:db)+"_production_backup.zip"
  end
end
