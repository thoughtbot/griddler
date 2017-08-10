require 'htmlentities'

module Griddler
  class Email
    include ActionView::Helpers::SanitizeHelper
    attr_reader :to, :from, :cc, :bcc, :subject, :raw_body, :raw_text, :raw_html, :content_ids, :headers, :raw_headers, :attachments

    def initialize(params)
      @params = params

      @to = recipients(:to)
      @from = extract_address(params[:from])
      @subject = extract_subject

      @raw_text = clean_raw_utf8(params[:text])
      @raw_html = clean_raw_utf8(params[:html])
      @raw_body = @raw_text.presence || @raw_html

      @headers = extract_headers
      @content_ids = params['content-ids']
      @cc = recipients(:cc)
      @bcc = recipients(:bcc)

      @raw_headers = params[:headers]

      @attachments = params[:attachments]
    end

    private

    attr_reader :params

    def config
      @config ||= Griddler.configuration
    end

    def recipients(type)
      params[type].to_a.map { |recipient| extract_address(recipient) }
    end

    def extract_address(address)
      EmailParser.parse_address(clean_invalid_utf8_bytes(address))
    end

    def extract_subject
      clean_invalid_utf8_bytes(params[:subject])
    end


    ##to delete
    def extract_body
      text = EmailParser.extract_reply_body(text_or_sanitized_html)
      text = clean_raw_text(text) if params.fetch(:text, '').presence
      text
    end

    def extract_headers
      if params[:headers].is_a?(Hash)
        deep_clean_invalid_utf8_bytes(params[:headers])
      else
        EmailParser.extract_headers(clean_invalid_utf8_bytes(params[:headers]))
      end
    end

    def extract_cc_from_headers(headers)
      EmailParser.extract_cc(headers)
    end

    def text_or_sanitized_html
      text = clean_invalid_utf8_bytes(params.fetch(:text, ''))
      text.presence || clean_raw_html(params.fetch(:html, '')).presence
    end


    ##to delete
    def clean_raw_text(text)
      cleaned_text = clean_invalid_utf8_bytes(text)
      full_sanitizer = Rails::Html::FullSanitizer.new
      cleaned_text = full_sanitizer.sanitize(cleaned_text)
      cleaned_text = HTMLEntities.new.decode(cleaned_text)
      cleaned_text
    end

    ##to delete
    def clean_raw_html(html)
      cleaned_html = clean_invalid_utf8_bytes(html)
      cleaned_html = sanitize(cleaned_html)
      cleaned_html = HTMLEntities.new.decode(cleaned_html)
      cleaned_html
    end

    def clean_raw_utf8(text)
      clean_invalid_utf8_bytes(text) || ''
    end

    def deep_clean_invalid_utf8_bytes(object)
      case object
      when Hash
        object.inject({}) do |clean_hash, (key, dirty_value)|
          clean_hash[key] = deep_clean_invalid_utf8_bytes(dirty_value)
          clean_hash
        end
      when Array
        object.map { |element| deep_clean_invalid_utf8_bytes(element) }
      when String
        clean_invalid_utf8_bytes(object)
      else
        object
      end
    end

    def clean_invalid_utf8_bytes(text)
      if text && !text.valid_encoding?
        text.force_encoding('ISO-8859-1').encode!('UTF-8')
      else
        text
      end
    end
  end
end
