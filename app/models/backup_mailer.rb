class BackupMailer < ActionMailer::Base
  def backup_file(zipfile)
    recipients  'Les Nightingill<les@stillpointoftheturningworld.com>'
    from        "ORI Database Administrator<#{ADMIN_EMAIL}>"
    headers     "Reply-to" => "#{ADMIN_EMAIL}", "Message-ID"=>"<#{DateTime.now.to_formatted_s(:number)}@orphansofrwanda.info>"
    subject     "ORI daily backup file"
    attachment :content_type => "application/x-gzip", :body => zipfile, :filename => DateTime.now.to_formatted_s(:db)+"_production_backup.zip"
  end
end
