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
      Griddler::EmailClientsSpliter.send(email_client(headers), doc)
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
    trait = email_client_trait(headers)
    client_patterns.each do |client, pattern|
      return client if pattern.match?(trait)
    end
    :default
  end

  # patterns 有先后的顺序
  def self.client_patterns
    {
      outlook_mac: /Microsoft-MacOutlook/i,
      outlook_web: /prod\.outlook\.com/,
      icloud:      /icloud\.com/, # 现在 Apple 的 iPhone, Mac, iPad 都可以统一处理, 未来再看是否需要额外处理.
      gmail:       /mail\.gmail\.com/
    }
  end

  # 通过 User-Agnet, From, 与 Message-Id 来进行判断. 获取能够产生 trait 标记的方法
  def self.email_client_trait(headers)
    [headers['User-Agent'], headers['Message-Id'], headers['From']].join(' ')
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
      /^[[:space:]]*\d{4}[-\/]\d{1,2}[-\/]\d{1,2}[[:space:]].*[[:space:]]<.*>?$/i,
      /(_)*\n[[:space:]]*De :.*\n[[:space:]]*Envoyé :.*\n[[:space:]]*À :.*\n[[:space:]]*Objet :.*\n$/i, # French Outlook
      /^[[:space:]]*\>?[[:space:]]*Le.*<\n?.*>.*\n?a[[:space:]]?\n?écrit :$/, # French
      /^[[:space:]]*\>?[[:space:]]*El.*<\n?.*>.*\n?escribió:$/ # Spanish
    ]
  end

  def self.remove_reply_portion(body)
    regex_split_points.inject(body) do |result, split_point|
      result.split(split_point).first || ""
    end
  end
end
