class Griddler::EmailsController < ActionController::Base
  def create
    normalized_params.each do |p|
      process_email Griddler::Email.new(p)
    end

    head :ok
  end

  private

  def normalized_params
    Array.wrap(Griddler.configuration.email_service.normalize_params(params))
  end

  def process_email(email)
    processor_class  = Griddler.configuration.processor_class
    processor_method = Griddler.configuration.processor_method
    processor_class.public_send(processor_method, email)
  end
end
