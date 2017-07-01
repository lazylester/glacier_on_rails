require 'glacier_on_rails/config'
class ApplicationFile
  attr_accessor :file
  def initialize(file)
    # file may be a Pathname instance or a string
    @file = file.to_s
  end

  def contents
    ActiveSupport::Gzip.compress(File.read(file))
  end

  def filename
    File.basename(file)
  end

  def self.list
    files.map{|f| new(f) }.map(&:filename)
  end

  def self.files
    Dir.glob(GlacierOnRails::Config.attached_files_directory.join('*'))
  end

end
