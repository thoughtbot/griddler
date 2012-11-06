require 'iconv'

class Griddler::Email
  attr_accessor :to, :from, :body, :subject

  def initialize(params)
    @to = extract_address(params[:to], config.to)
    @from = extract_address(params[:from], :email)
    @subject = params[:subject]

    if config.raw_body
      @body = params[:text]
    else
      @body = extract_body(params[:text], params[:charsets])
    end

    handler_class = config.handler_class
    handler_method = config.handler_method
    handler_class.send(handler_method, self)
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

  def extract_body(body_text, charsets)
    if charsets.present?
      charsets = ActiveSupport::JSON.decode(charsets)
      body_text = Iconv.new('utf-8', charsets['text']).iconv(body_text)
    end

    EmailParser.extract_reply_body(body_text)
  end

  def config
    Griddler.configuration
  end
end
