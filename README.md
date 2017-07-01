# GlacierOnRails

Rails engine with utilities for backup and restore of entire application database to the Amazon AWS Glacier service.
Includes rake tasks that may be invoked by cron task to archive a daily backup.
Archives both the database and attached files, where the storage of attached files follows the scheme of the [refile gem](https://github.com/refile/refile). Specifically, attached files are immutable, two files with the same filename are presumed to be identical. If a file exists in the attached files directory, it is not restored from the archive during a restore operation. All files in the attached files directory are archived individually, exactly once.

Include this in your application Gemfile:

```
gem 'glacier_on_rails', :git => 'git://github.com/lazylester/glacier_on_rails.git'
```

The _index partial is intended for inclusion into a page in the main application.

Dependencies required to be present in the main application are:
* jQuery
* ractive.js
* underscore.js

Run model test suites with:
```
  rspec spec/models
```

Run feature specs with:
```
  rspec spec/features
```

Run all the tests with:
```
  rake
```

Configure in the main application, in config/initializers/glacier_on_rails.rb:
```ruby
  if defined? GlacierOnRails
    require 'glacier_on_rails/config'
    GlacierOnRails::Config.setup do |config|
      config.attached_files_directory = FileUploadLocation.join('store')
      config.aws_region = 'us-east-1'
    end

    AwsLog.logger.level = 'debug' # possible values are: 'debug', 'info', 'warn', 'error', 'fatal'
                                  # 'debug' is the most liberal, 'fatal' the most restrictive
  end
```
## Cron control
The rake task:
```
rake aws:create_db_archive
```
may be invoked from your cron job in order to create a periodic, automatic backup.

## GlacierArchive model and its lifecycle

The database and each of the file attachments are archived and restored individually, this dramatically reduces the resources consumed by backup, including Glacier storage and network bandwidth, since most of the file attachments are likely unchanged between backups, so it is unnecessary to back them up periodically.

It is assumed that file attachments to Rails models are handled in the manner of the [refile gem](https://github.com/refile/refile). Each file is given a unique name for storage, and the files are never changed. If a file attached to an ActiveRecord model is replaced, it is given a new unique name. Attached files are individually backed up to AWS Glacier, if an attached file has already been backed up to AWS Glacier, the backup is skipped.

Similarly during restoral, if a file exists in the attached files directory, it is not retrieved from AWS Glacier.

The ApplicationDataBackup model manages the backup and restoral of the database and all file attachments.

The GlacierArchive model has a retrieval_status property, indicating its lifecycle status:

Status    | Meaning
----------|-----------------------------------------------------------------------------------------------------------------------
exists    | The attached file is present in the filesystem, retrieval/restoral presumed unnecessary.
available | The attached file (or database backup file) has previously been archived to Glacier.
pending   | An archieve retrieval job has been initiated at Glacier, notification of completion is awaited (can take a few hours).
ready     | Notification has been received that the archive is ready for download.
local     | The archive has been downloaded and is present locally, available for restoral.

## Database backup and restore
Database tables application_data_backups and glacier_archives are used to store objects related to this gem. So database restoral is selective and excludes these two tables. This is so that the database can be restored to its version of (say) one week ago, and can subsequently be restored to its version from yesterday, even though the week-ago version did not contain ApplicationDataBackup and GlacierArchiv objects from yesterday.

This is achieved using the pg_restore selective restoral facility which first generates a list of objects to be restored, which we edit to remove excluded objects, and then restores the database controlled by the list.

## Restoral of attached files
If the database is restored to an older version, there may be some attached files in the filesystem that now do not have associated ActiveRecord models. Rather than just delete these, they are moved to a directory called "orphan_files" so that they can be handled manually.

## Logger
A logger is used, with the log messages appended to in log/aws.log. Consider a rotation strategy for this file.

## AWS credentials
Stored in a .aws/credentials file in the home directory. (see [AWS sdk documentation](http://docs.aws.amazon.com/sdk-for-ruby/v2/developer-guide/setup-config.html) With contents:

```markdown
[default]
account_id = your_account_id
aws_access_key_id = your_access_key_id
aws_secret_access_key = your_aws_secret_access_key

```

## Database access parameters
The pg_restore command depends on the existence of a file called ~/.pgpass, containing access parameters for the database. (See [Postgres documentation](https://www.postgresql.org/docs/9.3/static/libpq-pgpass.html) for format details).
