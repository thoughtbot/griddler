require 'htmlentities'

module Griddler
  class Email
    include ActionView::Helpers::SanitizeHelper
    attr_reader :to, :from, :cc, :bcc, :subject, :body, :raw_body, :raw_text, :raw_html,
      :headers, :raw_headers, :attachments

    def initialize(params)
      @params = deep_clean_invalid_utf8_bytes(params)

      @to = recipients(:to)
      @from = extract_address(params[:from])
      @subject = params[:subject]

      @body = extract_body
      @raw_text = params[:text]
      @raw_html = params[:html]
      @raw_body = @raw_text.presence || @raw_html

      @headers = extract_headers

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
      EmailParser.parse_address(address)
    end

    def extract_body
      EmailParser.extract_reply_body(text_or_sanitized_html)
    end

    def extract_headers
      if params[:headers].is_a?(Hash)
        params[:headers]
      else
        EmailParser.extract_headers(params[:headers])
      end
    end

    def extract_cc_from_headers(headers)
      EmailParser.extract_cc(headers)
    end

    def text_or_sanitized_html
      text = params.fetch(:text, '')
      text.presence || clean_html(params.fetch(:html, '')).presence
    end

    def clean_html(html)
      cleaned_html = strip_tags(html)
      cleaned_html = HTMLEntities.new.decode(cleaned_html)
      cleaned_html
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
        text.force_encoding('ISO-8859-1').encode('UTF-8')
      else
        text
      end
    end
  end
end
