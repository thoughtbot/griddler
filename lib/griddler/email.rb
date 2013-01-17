class Griddler::Email
  attr_accessor :to, :from, :body, :raw_body, :subject, :attachments

  def initialize(params)
    @to = extract_address(params[:to], config.to)
    @from = extract_address(params[:from], :email)
    @subject = params[:subject]
    @body = extract_body(params)
    @raw_body = params[:text]
    @attachments = extract_attachments(params)

    processor_class = config.processor_class
    processor_class.process(self)
  end

  private

  def config
    Griddler.configuration
  end

  def extract_address(address, type)
    parsed = EmailParser.parse_address(address)
    if type == :hash
      parsed
    else
      parsed[type]
    end
  end

  def extract_attachments(params)
    attachment_count = params[:attachments].to_i
    attachment_files = []

    attachment_count.times do |index|
      attachment_files << params["attachment#{index + 1}".to_sym]
    end

    attachment_files
  end

  def extract_body(params)
    body_text = params[:text]
    charsets = params[:charsets]

    if charsets.present?
      charsets = ActiveSupport::JSON.decode(charsets)
      body_text = body_text.encode('UTF-8', invalid: :replace,
        undef: :replace, replace: '').force_encoding('UTF-8')
    end

    EmailParser.extract_reply_body(body_text)
  end
end
