module Griddler
  class Error < StandardError
  end

  module Errors
    class EmailServiceAdapterNotFound < Griddler::Error
    end
  end
end
