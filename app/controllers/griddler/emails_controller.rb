class Griddler::EmailsController < ActionController::Base
  skip_before_action :verify_authenticity_token, raise: false
  before_action :logging, only: :create

  def create
    begin
      normalized_params.each do |p|
        process_email email_class.new(p)
      end
    rescue
      sentry.capture_exception("Error in Griddler#create", extra: normalized_params)
    end

    head :ok
  end

  private

  delegate :processor_class, :email_class, :processor_method, :email_service, :sentry, :logger, to: :griddler_configuration

  private :processor_class, :email_class, :processor_method, :email_service, :sentry, :logger

  def normalized_params
    Array.wrap(email_service.normalize_params(params))
  end

  def process_email(email)
    processor_class.new(email).public_send(processor_method)
  end

  def griddler_configuration
    Griddler.configuration
  end

  def logging
    begin
      @log_hash = {
        is_griddler: true,
        griddler_from: "griddler_emails_controller",
        tag: "griddler_tag",
        griddler_params: params,
        griddler_normalized_params: normalized_params,
        griddler_date: DateTime.now
      }
      logger.info(@log_hash)
    rescue
    end
  end
end
