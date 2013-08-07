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
  def self.parse_address(full_address)
    email_address = extract_email_address(full_address)
    token, host = split_address(email_address)
    {
      token: token,
      host: host,
      email: email_address,
      full: full_address,
    }
  end

  def self.extract_reply_body(body)
    if body.blank?
      ""
    else
      reply_body = body.gsub(/On.*wrote:/, '').
        gsub(/^\s*On.*\r?\n?\s*.*\s*wrote:$/,'')

      split_points = [
        reply_delimeter_regex,
        /^\s*[-]+\s*Original Message\s*[-]+\s*$/,
        /^\s*--\s*$/
      ]

      split_points.each do |regex|
        reply_body = reply_body.split(regex).first || ""
      end

      reply_body.split(/[\r]*\n/)
        .reject do |line|
          line =~ /^\s*>/ ||
            line =~ /^\s*Sent from my /
        end.
        join("\n").
        strip
    end
  end

  def self.extract_headers(raw_headers)
    header_fields = Mail::Header.new(raw_headers).fields

    header_fields.inject({}) do |header_hash, header_field|
      header_hash[header_field.name.to_s] = header_field.value.to_s
      header_hash
    end
  end

  private

  def self.reply_delimeter_regex
    delimiter = Array(Griddler.configuration.reply_delimiter).join('|')
    %r{#{delimiter}}
  end

  def self.extract_email_address(full_address)
    full_address.split('<').last.delete('>').strip
  end

  def self.split_address(email_address)
    email_address.try :split, '@'
  end
end
