require 'spec_helper'

describe Griddler::Adapters::SendgridAdapter, '.normalize_params' do
  include Griddler::FixturesHelper

  it 'changes attachments to an array of files' do
    params = default_params.merge(
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
    )

    normalized_params = normalize_params(params)
    normalized_params[:attachments].should eq [upload_1, upload_2]
    normalized_params.should_not have_key(:attachment1)
    normalized_params.should_not have_key(:attachment2)
    normalized_params.should_not have_key(:attachment_info)
  end

  it 'has no attachments' do
    params = default_params.merge(attachments: '0')

    normalized_params = normalize_params(params)
    normalized_params[:attachments].should be_empty
  end

  it 'wraps to in an array' do
    normalized_params = normalize_params(default_params)

    normalized_params[:to].should eq [default_params[:to]]
  end

  it 'wraps cc in an array' do
    normalized_params = normalize_params(default_params)

    normalized_params[:cc].should eq [default_params[:cc]]
  end

  it 'returns an array even if cc is empty' do
    params = default_params.merge(cc: nil)
    normalized_params = normalize_params(params)

    normalized_params[:cc].should eq []
  end

  it 'returns the envelope as a hash' do
    normalized_params = normalize_params(default_params)
    envelope = normalized_params[:envelope]

    envelope.should be_present
    envelope[:to].should eq normalized_params[:to]
    envelope[:from].should eq normalized_params[:from]
  end

  it 'does not explode if envelope is not JSON-able' do
    params = default_params.merge(envelope: 'This is not JSON')

    normalize_params(params)[:envelope].should be_nil
  end

  it 'returns the charsets as a hash' do
    normalized_params = normalize_params(default_params)
    charsets = normalized_params[:charsets]

    charsets.should be_present
    charsets[:text].should eq 'iso-8859-1'

    %i[to from cc subject html].each do |field|
      charsets[field].should eq 'UTF-8'
    end
  end

  it 'does not explode if charsets is not JSON-able' do
    params = default_params.merge(charsets: 'This is not JSON')

    normalize_params(params)[:charsets].should be_nil
  end

  it 'includes SPF' do
    normalize_params(default_params)[:spf].should eq default_params[:SPF]
  end

  %i[dkim spam_score spam_report].each do |param|
    it "includes #{param}" do
      normalize_params(default_params)[param].should eq default_params[param]
    end
  end

  def normalize_params(params)
    Griddler::Adapters::SendgridAdapter.normalize_params(params)
  end

  def default_params
    to, from = 'hi@example.com', 'there@example.com'

    {
      text: 'hi',
      to: to,
      cc: 'cc@example.com',
      from: from,
      envelope: { to: [to], from: from }.to_json,
      SPF: 'pass',
      charsets: charsets_json
    }
  end

  def charsets_json
    {
      to: "UTF-8",
      cc: "UTF-8",
      subject: "UTF-8",
      from: "UTF-8",
      html: "UTF-8",
      text: "iso-8859-1"
    }.to_json
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
