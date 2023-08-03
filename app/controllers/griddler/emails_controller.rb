class Griddler::EmailsController < ActionController::Base
  skip_before_action :verify_authenticity_token, raise: false

  def create
    params = normalized_params
    params.each do |p|
      begin
        puts({
          is_griddler: true,
          griddler_from: "params_each_griddler_emails_controller",
          tag: "missing_mail",
          email_class: email_class.new(p),
          griddler_date: DateTime.now,
          email_class_valid: email_class.new(p).valid?
        }.to_json)
      rescue
      end
      process_email email_class.new(p)
    end

    begin
      puts({
        tag: "missing_mail",
        griddler_date: DateTime.now,
        is_griddler: true,
        griddler_from: "griddler_emails_controller",
        normalized_params: params
      }.to_json)
    rescue
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
