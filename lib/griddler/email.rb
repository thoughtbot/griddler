require 'htmlentities'

class Griddler::Email
  include ActionView::Helpers::SanitizeHelper
  attr_reader :to, :from, :body, :raw_body, :subject, :attachments

  def initialize(params)
    case config.mail_service
    when :send_grid
      load_post_params(params)
    when :cloud_mailin
      formatted_params = format_post_from_cloudmailin(params)
      load_post_params(formatted_params)
    end

  end

  def load_post_params(params)
    @params = params
    @to = extract_address(params[:to], config.to)
    @from = extract_address(params[:from], :email)
    @subject = params[:subject]
    @body = extract_body
    @raw_body = params[:text] || params[:html]
    @attachments = extract_attachments
  end

  def process
    processor_class = config.processor_class
    processor_class.process(self)
  end

  private

  attr_reader :params

  def config
    Griddler.configuration
  end

  def format_post_from_cloudmailin(params)
    params = {
      to: params[:envelope][:to],
      from: params[:envelope][:from],
      subject: params[:headers][:Subject],
      text: params[:plain],
      html: params[:html],
      attachments: params[:attachments]
      }
  end

  def extract_address(address, type)
    parsed = EmailParser.parse_address(address)

    if type == :hash
      parsed
    else
      parsed[type]
    end
  end

  def extract_attachments
    return params[:attachments] if config.mail_service == :cloud_mailin
    attachment_count = params[:attachments].to_i

    attachment_count.times.map do |index|
      params["attachment#{index + 1}".to_sym]
    end
  end

  def extract_body
    body_text = text_or_sanitized_html

    if params[:charsets].present?
      body_text = body_text.encode(
        'UTF-8',
        invalid: :replace,
        undef: :replace,
        replace: ''
      ).force_encoding('UTF-8')
    end

    EmailParser.extract_reply_body(body_text)
  end

  def text_or_sanitized_html
    if params.key? :text
      clean_text(params[:text])
    elsif params.key? :html
      clean_html(params[:html])
    else
      raise Griddler::Errors::EmailBodyNotFound
    end
  end

  def clean_text(text)
    clean_invalid_utf8_bytes(text)
  end

  def clean_html(html)
    cleaned_html = clean_invalid_utf8_bytes(html)
    cleaned_html = strip_tags(cleaned_html)
    cleaned_html = HTMLEntities.new.decode(cleaned_html)
    cleaned_html
  end

  def clean_invalid_utf8_bytes(text)
    text.encode(
      'UTF-8',
      'binary',
      invalid: :replace,
      undef: :replace,
      replace: ''
    )
  end
end
