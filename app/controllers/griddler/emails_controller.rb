class Griddler::EmailsController < ActionController::Base
  def create
    normalized_params.each do |p|
      process_email Griddler::Email.new(p)
    end

    head :ok
  end

  private

  delegate :processor_class, :processor_method, :email_service, to: :griddler_configuration

  def normalized_params
    Array.wrap(email_service.normalize_params(params))
  end

  def process_email(email)
    processor_class.new(email).public_send(processor_method)
  end

  def griddler_configuration
    Griddler.configuration
  end
end
