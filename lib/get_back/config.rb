# see http://stackoverflow.com/questions/20734766/rails-mountable-engine-how-should-apps-set-configuration-variables
module GetBack
  class Config
    class << self
      cattr_accessor :attached_files_directory, :aws_region, :profile_name
      self.attached_files_directory = nil
      self.aws_region = 'us-east-1'
      self.profile_name = 'default'

      alias_method :setup, :tap
      # add default values of more config vars here
    end
  end
end
