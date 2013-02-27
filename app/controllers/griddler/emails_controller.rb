class Griddler::EmailsController < ActionController::Base
  def create
    Griddler::Email.new(normalized_params).process
    head :ok
  end

  private

  def normalized_params
    Griddler.configuration.email_service.normalize_params(params)
  end
end
