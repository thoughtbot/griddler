require 'spec_helper'

describe Griddler::Adapters::CloudmailinAdapter, '.normalize_params' do
  include Griddler::FixturesHelper

  it 'normalizes parameters' do
    Griddler::Adapters::CloudmailinAdapter.normalize_params(default_params).should be_normalized_to({
      to: ['Some Identifier <some-identifier@example.com>'],
      cc: ['emily@example.com'],
      from: 'Joe User <joeuser@example.com>',
      subject: 'Re: [ThisApp] That thing',
      text: /Dear bob/
    })
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

  def default_params
    {
      envelope: { to: 'Some Identifier <some-identifier@example.com>', from: 'Joe User <joeuser@example.com>' },
      headers: { Subject: 'Re: [ThisApp] That thing', Cc: 'emily@example.com' },
      plain: <<-EOS.strip_heredoc.strip
        Dear bob

        Reply ABOVE THIS LINE

        hey sup
      EOS
    }
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
