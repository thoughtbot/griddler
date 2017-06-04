require 'htmlentities'

module Griddler
  class Email
    include ActionView::Helpers::SanitizeHelper

    attr_reader :to,
                :from,
                :cc,
                :bcc,
                :original_recipient,
                :reply_to,
                :subject,
                :body,
                :raw_body,
                :raw_text,
                :raw_html,
                :date,
                :headers,
                :raw_headers,
                :attachments,
                :vendor_specific,
                :spam_report

    def initialize(params)
      @params = params

      @to = recipients(:to)
      @from = extract_address(params[:from])
      @subject = extract_subject

      @body = extract_body
      @raw_text = params[:text]
      @raw_html = params[:html]
      @raw_body = @raw_text.presence || @raw_html

      @headers = extract_headers

      @cc = recipients(:cc)
      @bcc = recipients(:bcc)
      @original_recipient = extract_address(params[:original_recipient])
      @reply_to = extract_address(params[:reply_to])

      @date = params[:date]

      @raw_headers = params[:headers]

      @attachments = params[:attachments]

      @vendor_specific = params.fetch(:vendor_specific, {})

      @spam_report = params[:spam_report]
    end

    def to_h
      @to_h ||= {
        to: to,
        from: from,
        cc: cc,
        bcc: bcc,
        subject: subject,
        body: body,
        raw_body: raw_body,
        raw_text: raw_text,
        raw_html: raw_html,
        date: date,
        headers: headers,
        raw_headers: raw_headers,
        attachments: attachments,
        vendor_specific: vendor_specific,
        spam_score: spam_score,
        spam_report: spam_report,
      }
    end

    def spam_score
      @spam_report[:score] if @spam_report
    end

    private

    attr_reader :params

    def config
      @config ||= Griddler.configuration
    end

    def recipients(type)
      params[type].to_a.reject(&:empty?).map do |recipient|
        extract_address(recipient)
      end.compact
    end

    def extract_address(address)
      clean_address = clean_text(address)
      EmailParser.parse_address(clean_address) if clean_address =~ /@/
    end

    def extract_subject
      clean_text(params[:subject])
    end

    def extract_body
      EmailParser.extract_reply_body(text_or_sanitized_html)
    end

    def extract_headers
      if params[:headers].is_a?(Hash)
        deep_clean_invalid_utf8_bytes(params[:headers])
      elsif params[:headers].is_a?(Array)
        deep_clean_invalid_utf8_bytes(params[:headers])
      else
        EmailParser.extract_headers(clean_invalid_utf8_bytes(params[:headers]))
      end
    end

    def extract_cc_from_headers(headers)
      EmailParser.extract_cc(headers)
    end

    def text_or_sanitized_html
      text = clean_text(params.fetch(:text, ''))
      text.presence || clean_html(params.fetch(:html, '')).presence
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
