# encoding: utf-8
require 'htmlentities'
require 'nokogiri'

module Griddler
  class Email
    include ActionView::Helpers::SanitizeHelper
    attr_reader :to, :from, :subject, :body, :body_text, :body_html, 
                :raw_body, :raw_text, :raw_html, :raw_body_html,
                :headers, :raw_headers, :attachments, :cc, :bcc, :signature

    def initialize(params)
      @params = params

      @to = recipients
      @cc = parse_ccs
      @bcc = parse_bccs
      @from = extract_address(params[:from], config.from)
      @subject = params[:subject]

      @body = extract_body
      @body_text = extract_text
      @body_html = extract_html
      @signature = extract_signature
      @raw_text = params[:text]
      @raw_html = params[:html]
      @raw_body_html = extract_body_html
      @raw_body = @raw_text || @raw_html

      @headers = extract_headers
      @raw_headers = params[:headers]

      @attachments = params[:attachments]
    end

    def process
      processor_class = config.processor_class
      processor_class.process(self)
    end

    def email_regex
      /[\w+.=-]+(?<!(?:jpg|png|jpeg|gif))@(?!.*(?:jpg|png|jpeg|gif))[\w.-]*[\w]/
    end

    def bounce_format
      recipients.any?{|address| address =~ /^bounce.*-(.+)=(.+)@/ }
    end

    def included_emails
      return @included_emails unless @included_emails.nil?
      emails = to.collect{|r| r[:email]} + cc.collect{|r| r[:email]} + bcc.collect{|r| r[:email]}
      emails += addresses(raw_html.scan(email_regex), :email) unless raw_html.nil? || raw_html == ""
      emails += addresses(raw_text.scan(email_regex), :email) unless raw_text.nil? || raw_text == ""
      emails << extract_address(headers['X-Gm-Original-To'], :email) unless headers['X-Gm-Original-To'].nil? || headers['X-Gm-Original-To'] == ""
      emails = emails.compact.uniq
      @included_emails = emails
    end

    def smtp
      return scrub_smtp(params[:smtp]) unless params[:smtp].nil? || params[:smtp] == ""
      return scrub_smtp(headers['Message-ID']) unless headers.nil? || headers['Message-ID'].nil? || headers['Message-ID'] == ""
      return scrub_smtp(headers['Message-Id']) unless headers.nil? || headers['Message-Id'].nil? || headers['Message-Id'] == ""
      return nil
    end

    def in_reply_to
      return scrub_smtp(params[:in_reply_to]) unless params[:in_reply_to].nil? || params[:in_reply_to] == ""
      return scrub_smtp(headers['In-Reply-To']) unless headers.nil? || headers['In-Reply-To'].nil? || headers['In-Reply-To'] == ""
      return nil
    end

    def scrub_smtp(message_id)
      message_id.to_s.gsub(/\</, '').gsub(/\>/, '').strip
    end

    def bounced?
      return @bounced unless @bounced.nil?
      @to.any? do |recipient| 
        @bounced = true if recipient[:original_email] != recipient[:email] && 
                           recipient[:original_email] =~ EmailParser.bounce_format
        return @bounced unless @bounced.nil?
      end
      @bounced = false
    end

    def autoreply?
      return @autoreply unless @autoreply.nil?
      @to.any? do |recipient| 
        @autoreply = true if recipient[:original_email] != recipient[:email] && 
                             recipient[:original_email] =~ EmailParser.autoreply_format
        return @autoreply unless @autoreply.nil?
      end
      
      # list of rules from http://stackoverflow.com/questions/1027395/detecting-outlook-autoreply-out-of-office-emails
      @autoreply = true if headers['x-auto-response-suppress']
      @autoreply = true if headers['x-autorespond']
      
      precedences = %w(auto_reply bulk junk)
      @autoreply = true if precedences.include?(headers['precedence']) || precedences.include?(headers['x-precedence'])

      @autoreply = true if headers['auto-submitted'] == 'auto-replied'
      @autoreply = true if subject =~ autoreply_regex
      @autoreply = false unless @autoreply
      @autoreply
    end

    private

    attr_reader :params

    def config
      Griddler.configuration
    end

    def addresses(emails, kind = nil)
      kind ||= config.to
      return [] if emails.nil? || emails == ""
      emails.map { |recipient| extract_address(recipient, kind) }
    end

    def recipients
      addresses(params[:to])
    end

    def parse_ccs
      addresses(params[:cc])
    end

    def parse_bccs
      addresses(params[:bcc])
    end

    def extract_address(address, type)
      return nil if address.nil? || address == ""
      parsed = EmailParser.parse_address(address)

      if type == :hash
        parsed
      else
        parsed[type]
      end
    end

    def extract_body
      stripped = stripped_text_or_html
      return stripped unless stripped.nil? || stripped == ""
      EmailParser.extract_reply_body(text_or_sanitized_html)
    end

    def extract_text
      return clean_text(params[:stripped_text]) if params.key?(:stripped_text)
      EmailParser.extract_reply_body(clean_text(params[:text].to_s))
    end

    def extract_html
      return clean_html(params[:stripped_html]) if params.key?(:stripped_html)
      EmailParser.extract_reply_body(clean_html(params[:html].to_s))
    end

    def extract_body_html
      cleaned = params[:stripped_html] if params.key?(:stripped_html)
      cleaned ||= extract_html
      return nil if cleaned.nil? || cleaned == "" || params[:html].nil?
      html = clean_invalid_utf8_bytes(params[:html]).encode('UTF-8')
      html = $1 if html =~ /(.*#{ Regexp.escape(clean_invalid_utf8_bytes(cleaned).encode('UTF-8').split("\n").last) })/im
      html = Nokogiri.parse(html).to_html.strip # close any open tags
      html
    end

    def extract_signature
      return clean_html(params[:stripped_signature]) if params.key?(:stripped_signature)
      EmailParser.extract_replies(clean_html(text_or_sanitized_html))
    end

    def extract_headers
      EmailParser.extract_headers(params[:headers])
    end

    def stripped_text_or_html
      if params.key? :stripped_text
        clean_text(params[:stripped_text])
      elsif params.key? :stripped_html
        clean_html(params[:stripped_html])
      end
    end

    def text_or_sanitized_html
      if params.key? :text
        clean_text(params[:text])
      elsif params.key? :html
        clean_html(params[:html])
      end
    end

    def clean_text(text)
      clean_invalid_utf8_bytes(text)
    end

    def clean_html(html)
      return html if html.nil? || html == ""
      cleaned_html = clean_invalid_utf8_bytes(html)
      cleaned_html = strip_tags(cleaned_html)
      cleaned_html = HTMLEntities.new.decode(cleaned_html)
      cleaned_html
    end

    def clean_invalid_utf8_bytes(text)
      return text if text.nil? || text == ""
      if !text.valid_encoding?
        text = text
          .force_encoding('ISO-8859-1')
          .encode('UTF-8')
      end

      text
    end

    def autoreply_regex
      matchers = ['Auto:', 'Automatic reply', 'Autosvar', 'Automatisk svar', 'Automatisch antwoord', 'Abwesenheitsnotiz', 'Risposta Non al computer', 'Automatisch antwoord', 'Auto Response', 'Respuesta automática', 'Fuori sede', 'Out of Office', 'Frånvaro', 'Réponse automatique']
      Regexp.new("\\A(?:#{matchers.join('|')})",  Regexp::IGNORECASE | Regexp::MULTILINE)
    end
  end
end
