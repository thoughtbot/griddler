# Parse emails from their full format into a hash containing full email, host,
# local token, and the raw argument.
#
# Some Body <somebody@example.com>
# # => {
#   token: 'somebody',
#   host: 'example.com',
#   email: 'somebody@example.com',
#   full: 'Some Body <somebody@example.com>',
# }
require 'mail'

module Griddler::EmailParser
  CLIENT_PATTERNS = {
    # outlook web
    outlook_web: /prod\.outlook\.com/,
    gmail:       /mail\.gmail\.com/,
    icloud:      /icloud\.com/
  }

  class << self
    def parse_address(full_address)
      email_address = extract_email_address(full_address)
      name          = extract_name(full_address)
      token, host   = split_address(email_address)
      {
        token: token,
        host:  host,
        email: email_address,
        full:  full_address,
        name:  name,
      }
    end

    # html: html 的内容
    # client: 是哪一个 email client
    def extract_reply_html(html, headers = {})
      doc = Nokogiri::HTML.parse(html)
      case email_client(headers)
      when :outlook_web
        doc.at_css('body > #divtagdefaultwrapper').to_s
      when :gmail
        doc.at_css('body > .gmail_extra')&.remove
        doc.at_css('body').inner_html
      when :icloud
        # Apple Mail
        doc.at_css('body > div > blockquote[type=cite]')&.remove
        # iPhone
        doc.at_css('body > blockquote[type=cite]')&.remove
        doc.at_css('body').inner_html
      else
        # 默认尝试清楚 <blockquote class='griddler_quote'> 的元素
        doc.at_css('body > blockquote.griddler_quote')&.remove
        doc.to_s
      end
    end

    def extract_reply_body(body)
      if body.blank?
        ""
      else
        remove_reply_portion(body)
          .split(/[\r]*\n/)
          .reject do |line|
          line =~ /^[[:space:]]+>/ ||
            line =~ /^[[:space:]]*Sent from my /
        end.
          join("\n").
          strip
      end
    end

    def extract_headers(raw_headers)
      if raw_headers.is_a?(Hash)
        raw_headers
      else
        header_fields = Mail::Header.new(raw_headers).fields

        header_fields.inject({}) do |header_hash, header_field|
          header_hash[header_field.name.to_s] = header_field.value.to_s
          header_hash
        end
      end
    end
  end


  private

  # 判断 email client 是哪一个
  def self.email_client(headers)
    message_id = headers['Message-Id']
    CLIENT_PATTERNS.each do |client, pattern|
      return client if pattern.match?(message_id)
    end
  end

  def self.reply_delimeter_regex
    delimiter = Array(Griddler.configuration.reply_delimiter).join('|')
    %r{#{delimiter}}
  end

  def self.extract_email_address(full_address)
    full_address.split('<').last.delete('>').strip
  end

  def self.extract_name(full_address)
    full_address = full_address.strip
    name         = full_address.split('<').first.strip
    if name.present? && name != full_address
      name
    end
  end

  def self.split_address(email_address)
    email_address.try :split, '@'
  end

  def self.regex_split_points
    [
      reply_delimeter_regex,
      /^[[:space:]]*[-]+[[:space:]]*Original Message[[:space:]]*[-]+[[:space:]]*$/i,
      /^[[:space:]]*--[[:space:]]*$/,
      /^[[:space:]]*\>?[[:space:]]*On.*\r?\n?.*wrote:\r?\n?$/,
      /^On.*<\r?\n?.*>.*\r?\n?wrote:\r?\n?$/,
      /On.*wrote:/,
      /\*?From:.*$/i,
      /^[[:space:]]*\d{4}[-\/]\d{1,2}[-\/]\d{1,2}[[:space:]].*[[:space:]]<.*>?$/i
    ]
  end

  def self.remove_reply_portion(body)
    regex_split_points.inject(body) do |result, split_point|
      result.split(split_point).first || ""
    end
  end
end
