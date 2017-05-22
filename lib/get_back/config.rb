# see http://stackoverflow.com/questions/20734766/rails-mountable-engine-how-should-apps-set-configuration-variables
module GetBack
  class Config
    class << self
      cattr_accessor :include_dirs
      self.include_dirs = []

      alias_method :setup, :tap
      # add default values of more config vars here
    end
  end
end
