module Griddler
  class Error < StandardError
    begin
      puts({
        is_griddler: true,
        tag: "missing_mail",
        from: "module_griddler_errors",
        griddler_date: DateTime.now,
        griddler_error: "StandartError"
      }.to_json)
    rescue
    end
  end

  module Errors
    class EmailServiceAdapterNotFound < Griddler::Error
      begin
        puts({
          is_griddler: true,
          tag: "missing_mail",
          from: "module_griddler_errors",
          griddler_date: DateTime.now,
          griddler_error: "EmailServiceAdapterNotFound"
        }.to_json)
      rescue
      end
    end
  end
end
