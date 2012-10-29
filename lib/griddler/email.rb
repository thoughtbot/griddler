require 'iconv'

class Griddler::Email
  attr_accessor :to, :from, :body, :user, :comment

  def initialize(params)
    if params[:to]
      @to = extract_address(params[:to], config.to)
    end
    if params[:from]
      @from = extract_address(params[:from], :email)
    end
    @subject = params[:subject]

    if params[:charsets]
      charsets = ActiveSupport::JSON.decode(params[:charsets])
      @body = EmailParser.extract_reply_body(Iconv.new('utf-8', charsets['text']).iconv(params[:text]))
    else
      @body = EmailParser.extract_reply_body(params[:text])
    end
  end

  private
  def extract_address(address, type)
    parsed = EmailParser.parse_address(address)
    if type == :hash
      parsed
    else
      parsed[type]
    end
  end

  def config
    Griddler.configuration
  end
end
