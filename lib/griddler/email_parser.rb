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

  BOUNCE_FORMAT = /^bounce.*-(.+)=(.+)@/
  AUTOREPLY_FORMAT = /(.+)=(.+)@.*/

  def self.bounce_format
    BOUNCE_FORMAT
  end

  def self.autoreply_format
    AUTOREPLY_FORMAT
  end

  def self.parse_address(full_address)
    original_address = extract_email_address(full_address)
    email_address = reformat_email_address(original_address)
    name = extract_name(full_address)
    token, host = split_address(email_address)
    {
      token: token,
      host: host,
      email: email_address,
      original_email: original_address,
      full: full_address,
      name: name,
    }
  end

  def self.extract_reply_body(body)
    if body.blank?
      ""
    else
      remove_reply_portion(body)
        .split(/[\r]*\n/)
        .reject do |line|
          line =~ /^\s+>/ ||
            line =~ /^\s*Sent from my /
        end.
        join("\n").
        strip
    end
  end

  def self.extract_replies(body)
    return "" if body.nil? || body == ""
    regex_split_points.each do |split|
      result = body.split(split)
      return result.last if result.present? && result.count > 1
    end
    ""
  end

  def self.extract_headers(raw_headers)
    return raw_headers if raw_headers.is_a?(Hash)
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
    full_address.to_s.split('<').last.delete('>').strip
  end

  # outlook reformats reply-to address on bounce / autoresponse if from != reply-to
  def self.reformat_email_address(email)
    email = "#{$1}@#{$2}" if email =~ BOUNCE_FORMAT
    email = "#{$1}@#{$2}" if email =~ AUTOREPLY_FORMAT
    email
  end

  def self.extract_name(full_address)
    full_address = full_address.strip
    name = full_address.split('<').first.strip
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
      /^\s*[-]+\s*Original Message\s*[-]+\s*$/i,  # outlook default
      /^\s*--\s*$/,                               # standard sig delimeter
      /^_+$/,                                     # outlook default
      /On.*wrote:/,                               # apple mail
      /^\s*On.*\r?\n?\s*.*\s*wrote:$/,            # apple mail
      /^From:\s+/,                                # failsafe
      /^Sent from my/                             # mobile clients
    ]
  end

  def self.remove_reply_portion(body)
    regex_split_points.inject(body) do |result, split_point|
      result.split(split_point).first || ""
    end
  end
end
