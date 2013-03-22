require 'spec_helper'

describe Griddler::Adapters::PostmarkAdapter, '.normalize_params' do
  it 'normalizes parameters' do
    params = default_params

    normalized_params = Griddler::Adapters::PostmarkAdapter.normalize_params(params)
    normalized_params[:to].should eq ['bob@example.com']
    normalized_params[:from].should eq 'tdurden@example.com'
    normalized_params[:subject].should eq 'Reminder: First and Second Rule'
    normalized_params[:text].should include('Dear bob')
    normalized_params[:html].should include('<p>Dear bob</p>')
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
    params = default_params

    normalized_params = Griddler::Adapters::PostmarkAdapter.normalize_params(params)

    normalized_params[:ToFull].should be_nil
    normalized_params[:FromFull].should be_nil
    normalized_params[:Subject].should be_nil
    normalized_params[:TextBody].should be_nil
    normalized_params[:HtmlBody].should be_nil
    normalized_params[:Attachments].should be_nil
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

  def cwd
    File.expand_path File.dirname(__FILE__)
  end

  def upload_1_params
    @upload_1_params ||= begin
      file = File.new("#{cwd}/../../../spec/fixtures/photo1.jpg")
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
      file = File.new("#{cwd}/../../../spec/fixtures/photo2.jpg")
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
end
