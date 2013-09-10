require 'spec_helper'

describe Griddler::Adapters::MailgunAdapter, '.normalize_params' do
  it 'normalizes parameters' do
    Griddler::Adapters::MailgunAdapter.normalize_params(default_params).should be_normalized_to({
      to: ['alice@example.mailgun.org'],
      from: 'Bob <bob@11crows.mailgun.org>',
      subject: 'Re: Sample POST request',
      text: %r{Dear bob},
      html: %r{<p>Dear bob</p>}
    })
  end

  it 'passes the received array of files' do
    params = default_params.merge({
      'attachment-count' => 2,
      'attachment-1' => upload_1,
      'attachment-2' => upload_2
    })

    normalized_params = Griddler::Adapters::MailgunAdapter.normalize_params(params)
    normalized_params[:attachments].should eq [upload_1, upload_2]
  end

  it 'has no attachments' do
    params = default_params

    normalized_params = Griddler::Adapters::MailgunAdapter.normalize_params(params)
    normalized_params[:attachments].should be_empty
  end

  def default_params
    params = {
      recipient: 'alice@example.mailgun.org',
      sender: 'bob@example.mailgun.org',
      subject: 'Re: Sample POST request',
      from: 'Bob <bob@11crows.mailgun.org>',
      'body-plain' => text_body,
      'body-html' => text_html,
    }
  end

  def cwd
    File.expand_path File.dirname(__FILE__)
  end

  def upload_1
    @upload_1 ||= ActionDispatch::Http::UploadedFile.new({
      filename: 'photo1.jpg',
      type: 'image/jpeg',
      tempfile: File.new("#{cwd}/../../../spec/fixtures/photo1.jpg")
    })
  end

  def upload_2
    @upload_2 ||= ActionDispatch::Http::UploadedFile.new({
      filename: 'photo2.jpg',
      type: 'image/jpeg',
      tempfile: File.new("#{cwd}/../../../spec/fixtures/photo2.jpg")
    })
  end

  def text_body
    <<-EOS.strip_heredoc.strip
      Dear bob

      Reply ABOVE THIS LINE

      hey sup
    EOS
  end

  def text_html
    <<-EOS.strip_heredoc.strip
      <p>Dear bob</p>

      <p>Reply ABOVE THIS LINE</p>

      <p>hey sup</p>
    EOS
  end
end
