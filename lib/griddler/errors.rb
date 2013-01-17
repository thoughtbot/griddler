module Griddler
  class Error < StandardError
  end

  module Errors
    class EmailBodyNotFound < Griddler::Error
    end
  end
end
