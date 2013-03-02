module Griddler
  class Error < StandardError
  end

  module Errors
    class EmailBodyNotFound < Griddler::Error
    end

    class EmailServiceAdapterNotFound < Griddler::Error
    end
  end
end
