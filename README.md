= GetBack

Rails engine with utilities for backup and restore of entire application database to the Amazon AWS Glacier service.
Includes rake tasks that may be invoked by cron task to save a daily backup.

Include this in your application Gemfile:

```
gem 'get_back', :git => 'git://github.com/lazylester/get_back.git'
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

Configure in the main application, in config/initializers/get_back.rb:
```ruby
  if defined? GetBack
    require 'get_back/config'
    GetBack::Config.setup do |config|
      config.include_dirs = [FileUploadLocation.join('store')]
      config.aws_region = 'us-east-1'
    end

    AwsLog.logger.level = 'debug' # possible values are: 'debug', 'info', 'warn', 'error', 'fatal'
                                  # 'debug' is the most liberal, 'fatal' the most restrictive
  end
```

# Logger
A logger is used, with the log messages appended to in log/aws.log. Consider a rotation strategy for this file.

# AWS credentials
Stored in a .aws/credentials file in the home directory. (see [AWS sdk documentation](http://docs.aws.amazon.com/sdk-for-ruby/v2/developer-guide/setup-config.html) With contents:

```markdown
[default]
account_id = your_account_id
aws_access_key_id = your_access_key_id
aws_secret_access_key = your_aws_secret_access_key
```
