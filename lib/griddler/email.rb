require 'htmlentities'

class Griddler::Email
  include ActionView::Helpers::SanitizeHelper
  attr_accessor :to, :from, :body, :raw_body, :subject, :attachments

  def initialize(params)
    @to = extract_address(params[:to], config.to)
    @from = extract_address(params[:from], :email)
    @subject = params[:subject]
    @body = extract_body(params)
    @raw_body = params[:text] || params[:html]
    @attachments = extract_attachments(params)

    processor_class = config.processor_class
    processor_class.process(self)
  end

  private

  def config
    Griddler.configuration
  end

  def extract_address(address, type)
    parsed = EmailParser.parse_address(address)

    if type == :hash
      parsed
    else
      parsed[type]
    end
  end

  def extract_attachments(params)
    attachment_count = params[:attachments].to_i
    attachment_files = []

    attachment_count.times do |index|
      attachment_files << params["attachment#{index + 1}".to_sym]
    end

    attachment_files
  end

  def extract_body(params)
    body_text = text_or_sanitized_html(params)
    charsets = params[:charsets]

    if charsets.present?
      charsets = ActiveSupport::JSON.decode(charsets)
      body_text = body_text.encode('UTF-8', invalid: :replace,
        undef: :replace, replace: '').force_encoding('UTF-8')
    end

    EmailParser.extract_reply_body(body_text)
  end

  def text_or_sanitized_html(params)
    if params.key? :text
      clean_text(params[:text])
    elsif params.key? :html
      clean_html(params[:html])
    else
      raise Griddler::Errors::EmailBodyNotFound
    end
  end

  private

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
    text.encode('UTF-8', 'binary',
      invalid: :replace, undef: :replace, replace: '')
  end
end
