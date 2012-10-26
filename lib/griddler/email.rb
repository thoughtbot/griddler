require 'iconv'

class Griddler::Email
  attr_accessor :to, :from, :body, :user, :comment

  def initialize(params)
    @to   = extract_email_address(params[:to])
    @from = extract_email_address(params[:from])
    @subject = params[:subject]
    if params[:charsets]
      charsets = ActiveSupport::JSON.decode(params[:charsets])
      @body = extract_reply_body(Iconv.new('utf-8', charsets['text']).iconv(params[:text]))
    else
      @body = extract_reply_body(params[:text])
    end
  end

  private

  def extract_email_address(address)
    if address
      address = address.split('<').last
      if matches = address.match(Griddler::EmailFormat::Regex)
        address = matches[0]
      end
    end
    address
  end

  def parse_email(address)
    address =~ /^(\d+)@/
  end

  def extract_reply_body(body)
    if body
      body.split('Reply ABOVE THIS LINE').first.
        split(/^\s*[-]+\s*Original Message\s*[-]+\s*$/).first.
        split(/^\s*--\s*$/).first.
        split(/[\r]*\n/).reject { |line|
        line =~ /^\s*>/ || line =~ /^\s*On.*wrote:$/ || line =~ /^\s*Sent from my /
      }.join("\r\n").gsub(/^\s*On.*\r?\n?\s*.*\s*wrote:$/,'').strip
    end
  end
end
