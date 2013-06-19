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
    delimeter = Griddler.configuration.reply_delimiter
    if body.blank?
      ""
    elsif (bodies = body.split(delimeter).first.split(/^\s*[-]+\s*Original Message\s*[-]+\s*$/)).first.blank?
      self.get_body(bodies[1])
    else
      self.get_body(bodies[0])
    end
  end
  
  # use self.extract_reply_body or self.extract_reply_body_with_forwards to extract the body
  def self.get_body(text)
    text.split(/^\s*--\s*$/).first
        .gsub(/On.*wrote:/, '').
        split(/[\r]*\n/).reject do |line|
          line =~ /^\s*>/ ||
          line =~ /^\s*Sent from my /
        end.
        join("\n").
        gsub(/^\s*On.*\r?\n?\s*.*\s*wrote:$/,'').
        strip
  end

  def self.extract_headers(raw_headers)
    header_fields = Mail::Header.new(raw_headers).fields

    header_fields.inject({}) do |header_hash, header_field|
      header_hash[header_field.name.to_s] = header_field.value.to_s
      header_hash
    end
  end

  private

  def self.extract_email_address(full_address)
    full_address.split('<').last.delete('>').strip
  end

  def self.split_address(email_address)
    email_address.try :split, '@'
  end
end
