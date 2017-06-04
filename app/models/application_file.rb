require 'get_back/config'
class ApplicationFile
  attr_accessor :file
  def initialize(file)
    # file is a Pathname instance
    @file = file.to_s
  end

  def zipped_contents
    system("gzip -k #{file}")
    File.read(file+".gz")
  end

  def filename
    File.basename(file)
  end

  def self.list
    files.map{|f| new(f) }.map(&:filename)
  end

  def self.files
    Dir.glob(GetBack::Config.attached_files_directory.join('*'))
  end
end
