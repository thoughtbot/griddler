require 'spec_helper'

describe Griddler::Adapters::PostmarkAdapter, '.normalize_params' do
  include Griddler::FixturesHelper

  it 'normalizes parameters' do
    Griddler::Adapters::PostmarkAdapter.normalize_params(default_params).should be_normalized_to({
      to: ['Robert Paulson <bob@example.com>'],
      from: 'Tyler Durden <tdurden@example.com>',
      subject: 'Reminder: First and Second Rule',
      mailboxhash: '12_909090',
      text: /Dear bob/,
      html: %r{<p>Dear bob</p>}
    })
  end

  it 'passes the received array of files' do
    params = default_params.merge({ Attachments: [upload_1_params, upload_2_params] })

    normalized_params = Griddler::Adapters::PostmarkAdapter.normalize_params(params)

    first, second = *normalized_params[:attachments]

    first.original_filename.should eq('photo1.jpg')
    first.size.should eq(upload_1_params[:ContentLength])

    second.original_filename.should eq('photo2.jpg')
    second.size.should eq(upload_2_params[:ContentLength])
  end

  it 'has no attachments' do
    params = default_params

    normalized_params = Griddler::Adapters::PostmarkAdapter.normalize_params(params)

    normalized_params[:attachments].should be_empty
  end

  it 'gets rid of the original postmark params' do
    Griddler::Adapters::PostmarkAdapter.normalize_params(default_params).should be_normalized_to({
      ToFull: nil,
      FromFull: nil,
      Subject:  nil,
      TextBody: nil,
      HtmlBody: nil,
      Attachments: nil,
      MailboxHash: nil
    })
  end

  def default_params
    {
      FromFull: {
        Email: 'tdurden@example.com',
        Name: 'Tyler Durden'
      },
      ToFull: [{
        Email: 'bob@example.com',
        Name: 'Robert Paulson'
      }],
      Subject: 'Reminder: First and Second Rule',
      MailboxHash: '12_909090',
      TextBody: text_body,
      HtmlBody: text_html
    }
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

      Reply ABOVE THIS LINE

      hey sup
    EOS
  end

  def upload_1_params
    @upload_1_params ||= begin
      file = fixture_file('photo1.jpg')
      size = file.size
      {
        Name: 'photo1.jpg',
        Content: Base64.encode64(file.read),
        ContentType: 'image/jpeg',
        ContentLength: file.size
      }
    end
  end

  def upload_2_params
    @upload_2_params ||= begin
      file = fixture_file('photo2.jpg')
      size = file.size
      {
        Name: 'photo2.jpg',
        Content: Base64.encode64(file.read),
        ContentType: 'image/jpeg',
        ContentLength: file.size
      }
    end
  end

  def upload_1
    @upload_1 ||= ActionDispatch::Http::UploadedFile.new({
      filename: 'photo1.jpg',
      type: 'image/jpeg',
      tempfile: fixture_file('photo1.jpg')
    })
  end

  def upload_2
    @upload_2 ||= ActionDispatch::Http::UploadedFile.new({
      filename: 'photo2.jpg',
      type: 'image/jpeg',
      tempfile: fixture_file('photo2.jpg')
    })
  end
end
