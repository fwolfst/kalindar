require 'delegate'

# Delegator with some handy shortcuts
class Calendar < SimpleDelegator
  attr_accessor :filename
  # Write 'back' to file.
  def write_back!
    File.open(@filename, 'w') do |file|
      export_to file
    end
  end
end
