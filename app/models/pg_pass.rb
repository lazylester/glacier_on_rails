class PgPass

  class FileMissing < ApplicationDatabase::ConfigurationError
    def initialize
      message = "#{File.expand_path("~/.pgpass")} file not found, cannot dump database contents"
      super(message)
    end
  end

  class FilePermissionsError < ApplicationDatabase::ConfigurationError
    def initialize
      message = "password file #{File.expand_path("~/.pgpass")} has group or world access; permissions should be u=rw (0600)"
      super(message)
    end
  end

  def self.ensure
    # TODO missing file and permissions errors are recoverable
    # create or chmod the file instead of triggering an exception
    password_file = File.expand_path("~/.pgpass")
    raise FileMissing unless File.exists?(password_file)
    raise FilePermissionsError unless sprintf("%o", File.stat(password_file).mode) =~ /600$/
  end
end
