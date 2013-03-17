require 'spec_helper'

describe Griddler::Adapters::CloudmailinAdapter, '.normalize_params' do
  it 'normalizes parameters' do
    params = default_params

    normalized_params = Griddler::Adapters::CloudmailinAdapter.normalize_params(params)
    normalized_params[:to].should eq 'Some Identifier <some-identifier@example.com>'
    normalized_params[:from].should eq 'Joe User <joeuser@example.com>'
    normalized_params[:subject].should eq 'Re: [ThisApp] That thing'
    normalized_params[:text].should include('Dear bob')
  end

  it 'passes the received array of files' do
    params = default_params.merge({ attachments: [upload_1, upload_2] })

    normalized_params = Griddler::Adapters::CloudmailinAdapter.normalize_params(params)
    normalized_params[:attachments].should eq [upload_1, upload_2]
  end

  it 'has no attachments' do
    params = default_params

    normalized_params = Griddler::Adapters::CloudmailinAdapter.normalize_params(params)
    normalized_params[:attachments].should be_empty
  end

  it 'gets rid of the original cloudmailin params' do
    params = default_params

    normalized_params = Griddler::Adapters::CloudmailinAdapter.normalize_params(params)

    normalized_params[:envelope].should be_nil
  end

  def default_params
    params = {
      envelope: { to: 'Some Identifier <some-identifier@example.com>', from: 'Joe User <joeuser@example.com>' },
      headers: { Subject: 'Re: [ThisApp] That thing' },
      plain: <<-EOS.strip_heredoc.strip
        Dear bob

        Reply ABOVE THIS LINE

        hey sup
      EOS
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
end
