BACKUP_DIR = Rails.env.production? ? Rails.root.join("../../shared/backups") : "#{Rails.root}/db/backups/"
