require 'spec_helper'

describe Griddler::Adapters::MandrillAdapter, '.normalize_params' do
  it 'normalizes parameters' do
    params = default_params

    normalized_params = Griddler::Adapters::MandrillAdapter.normalize_params(params)
    normalized_params.each do |params|
      params[:to].should eq ['The Token <token@reply.example.com>']
      params[:from].should eq 'hernan@example.com'
      params[:subject].should eq 'hello'
      params[:text].should include('Dear bob')
      params[:html].should include('<p>Dear bob</p>')
      params[:raw_body].should include('raw')
    end
  end

  it 'passes the received array of files' do
    params = params_with_attachments

    normalized_params = Griddler::Adapters::MandrillAdapter.normalize_params(params)

    first, second = *normalized_params[0][:attachments]

    first.original_filename.should eq('photo1.jpg')
    first.size.should eq(upload_1_params[:length])

    second.original_filename.should eq('photo2.jpg')
    second.size.should eq(upload_2_params[:length])
  end

  it 'has no attachments' do
    params = default_params

    normalized_params = Griddler::Adapters::MandrillAdapter.normalize_params(params)

    normalized_params[0][:attachments].should be_empty
  end

  def default_params
    mandrill_events (params_hash*2).to_json
  end

  def params_hash
    [{
      event: "inbound",
      ts: 1364601140,
      msg:
        {
          raw_msg: "raw",
          headers: {},
          text: text_body,
          html: text_html,
          from_email: "hernan@example.com",
          from_name: "Hernan Example",
          to: [["token@reply.example.com", "The Token"]],
          subject: "hello",
          spam_report: {
            score: -0.8,
            matched_rules: "..."
            },
          dkim: {signed: true, valid: true},
          spf: {result: "pass", detail: "sender SPF authorized"},
          email: "token@reply.example.com",
          tags: [],
          sender: nil
        }
    }]
  end

  def params_with_attachments
    params = params_hash
    params[0][:msg][:attachments] = {
      'photo1.jpg' => upload_1_params,
      'photo2.jpg' => upload_2_params
    }
    mandrill_events params.to_json
  end

  def mandrill_events(json)
    { mandrill_events: json }
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
        name: 'photo1.jpg',
        content: Base64.encode64(file.read),
        type: 'image/jpeg',
        length: file.size
      }
    end
  end

  def upload_2_params
    @upload_2_params ||= begin
      file = File.new("#{cwd}/../../../spec/fixtures/photo2.jpg")
      size = file.size
      {
        name: 'photo2.jpg',
        content: Base64.encode64(file.read),
        type: 'image/jpeg',
        length: file.size
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
