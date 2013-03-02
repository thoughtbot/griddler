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
    if body.blank?
      ""
    else
      delimeter = Griddler.configuration.reply_delimiter
      body.split(delimeter).first.
        split(/^\s*[-]+\s*Original Message\s*[-]+\s*$/).first.
        split(/^\s*--\s*$/).first.
        gsub(/On.*wrote:/, '').
        split(/[\r]*\n/).reject do |line|
          line =~ /^\s*>/ ||
            line =~ /^\s*Sent from my /
        end.
        join("\n").
        gsub(/^\s*On.*\r?\n?\s*.*\s*wrote:$/,'').
        strip
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
