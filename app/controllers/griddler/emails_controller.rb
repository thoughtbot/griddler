class Griddler::EmailsController < ActionController::Base
  def create
    normalized_params = Griddler.configuration.email_service.normalize_params(params)
    Griddler::Email.new(normalized_params).process
    head :ok
  end
end
