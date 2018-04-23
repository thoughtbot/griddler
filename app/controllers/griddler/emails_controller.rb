class Griddler::EmailsController < ActionController::Base
  skip_before_action :verify_authenticity_token, raise: false

  def create
    normalized_params.each do |p|
      process_email email_class.new(p)
    end

    head :ok
  end

  private

  delegate :processor_class, :email_class, :processor_method, :email_service, to: :griddler_configuration

  private :processor_class, :email_class, :processor_method, :email_service

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
