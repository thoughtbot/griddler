require 'spec_helper'

describe Griddler::Adapters::CloudmailinAdapter, '.normalize_params' do
  it 'normalizes parameters' do
    params = {
      envelope: envelope,
      headers: headers,
      plain: <<-EOS.strip_heredoc.strip
        Dear bob

        Reply ABOVE THIS LINE

        hey sup
      EOS
    }

    normalized_params = Griddler::Adapters::CloudmailinAdapter.normalize_params(params)
    normalized_params[:to].should eq 'Some Identifier <some-identifier@example.com>'
    normalized_params[:from].should eq 'Joe User <joeuser@example.com>'
    normalized_params[:subject].should eq 'Re: [ThisApp] That thing'
    normalized_params[:text].should include('Dear bob')
  end

  it 'passes the received array of files' do
    params = {
      plain: 'hi',
      envelope: envelope,
      headers: headers,
      attachments: [ upload_1, upload_2 ]
    }

    normalized_params = Griddler::Adapters::CloudmailinAdapter.normalize_params(params)
    normalized_params[:attachments].should eq [upload_1, upload_2]
  end

  it 'has no attachments' do
    params = {
      text: 'hi',
      to: 'hi@example.com',
      from: 'there@example.com'
    }

    normalized_params = Griddler::Adapters::SendgridAdapter.normalize_params(params)
    normalized_params[:attachments].should be_empty
  end

  def envelope
    { to: 'Some Identifier <some-identifier@example.com>', from: 'Joe User <joeuser@example.com>' }
  end

  def headers
    { Subject: 'Re: [ThisApp] That thing' }
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
end
