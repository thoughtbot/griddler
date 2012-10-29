module EmailParser
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
    if body
      delimeter = Griddler.configuration.reply_delimiter
      body.split(delimeter).first.
        split(/^\s*[-]+\s*Original Message\s*[-]+\s*$/).first.
        split(/^\s*--\s*$/).first.
        split(/[\r]*\n/).reject do |line|
          line =~ /^\s*>/ ||
            line =~ /^\s*On.*wrote:$/ ||
            line =~ /^\s*Sent from my /
        end.
        join("\n").
        gsub(/^\s*On.*\r?\n?\s*.*\s*wrote:$/,'').
        strip
    end
  end

  private

  # Extract the email portion of an address in the format
  #
  #   Some Body <somebody@example.com>
  #   #=> somebody@example.com
  def self.extract_email_address(full_address)
    full_address.split('<').last.delete('>').strip
  end

  # Split email into token and host
  #
  #   somebody@example.com
  #   #=> [somebody, example.com]
  def self.split_address(email_address)
    email_address.try :split, '@'
  end
end
