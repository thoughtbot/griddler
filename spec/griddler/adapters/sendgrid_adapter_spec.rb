require 'spec_helper'

describe Griddler::Adapters::SendgridAdapter, '.normalize_params' do
  it 'changes attachments to an array of files' do
    params = {
      text: 'hi',
      to: 'hi@example.com',
      from: 'there@example.com',
      attachments: '2',
      attachment1: upload_1,
      attachment2: upload_2,
     'attachment-info' => <<-eojson
        {
          'attachment2': {
            'filename': 'photo2.jpg',
            'name': 'photo2.jpg',
            'type': 'image/jpeg'
          },
          'attachment1': {
            'filename': 'photo1.jpg',
            'name': 'photo1.jpg',
            'type': 'image/jpeg'
          }
        }
      eojson
    }

    normalized_params = Griddler::Adapters::SendgridAdapter.normalize_params(params)
    normalized_params[:attachments].should eq [upload_1, upload_2]
    normalized_params.should_not have_key(:attachment1)
    normalized_params.should_not have_key(:attachment2)
    normalized_params.should_not have_key(:attachment_info)
  end

  it 'has no attachments' do
    params = {
      text: 'hi',
      to: 'hi@example.com',
      from: 'there@example.com',
      attachments: '0'
    }

    normalized_params = Griddler::Adapters::SendgridAdapter.normalize_params(params)
    normalized_params[:attachments].should be_empty
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
