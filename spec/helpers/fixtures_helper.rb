module Griddler::FixturesHelper
  def fixture_file(file_name)
    cwd = File.expand_path File.dirname(__FILE__)
    File.new(File.join(cwd, '..', 'fixtures', file_name))
  end
end
