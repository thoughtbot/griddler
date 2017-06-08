require 'spec_helper'

describe Griddler::EmailParser do
  let(:outlook) { File.open('spec/fixtures/outlook.html').read }
  let(:outlook_mac) { File.open('spec/fixtures/outlook_mac.html').read }
  let(:gmail) { File.open('spec/fixtures/gmail.html').read }
  let(:apple_mail) { File.open('spec/fixtures/apple_mail.html').read }
  let(:iphone) { File.open('spec/fixtures/iphone.html').read }

  it 'outlook reply part' do
    allow(subject).to receive(:email_client).and_return(:outlook_web)

    h   = subject.extract_reply_html(outlook, :outlook_web)
    doc = Nokogiri::HTML.parse(h)
    # 回复区域(包含 Signature)
    expect(doc.css('#divtagdefaultwrapper').size).to eq 2
    # Signature 区域
    expect(doc.css('#Signature #divtagdefaultwrapper').size).to eq 1
    expect(doc.at_css('img')['src']).to eq 'cid:aedd9c1c-3d21-4c14-97c5-52921c77bbb5'
  end

  it 'outlook_mac reply part' do
    allow(subject).to receive(:email_client).and_return(:outlook_mac)

    h   = subject.extract_reply_html(outlook_mac, :outlook_web)
    doc = Nokogiri::HTML.parse(h)
    expect(doc.css('.MsoListParagraph').size).to eq 2
    expect(doc.css('body > .MsoNormal').size).to eq 11
  end

  it 'gmail reply part' do
    allow(subject).to receive(:email_client).and_return(:gmail)
    h   = subject.extract_reply_html(gmail, :gmail)
    doc = Nokogiri::HTML.parse(h)
    expect(doc.css('.gmail_extra').size).to eq 0
    expect(doc.at_css('img')['src']).to eq 'cid:ii_1595dc15e116b681'
  end

  it 'apple_mail reply part' do
    allow(subject).to receive(:email_client).and_return(:icloud)
    h   = subject.extract_reply_html(apple_mail, :icloud)
    doc = Nokogiri::HTML.parse(h)
    expect(doc.css('blockquote[type=cite]').size).to eq 0
    expect(doc.at_css('img')['src']).to eq 'cid:555F7AEF-4A81-4E01-9B10-1393395B7B2A'
  end

  it 'apple iphone reply part' do
    allow(subject).to receive(:email_client).and_return(:icloud)
    h   = subject.extract_reply_html(iphone, :icloud)
    doc = Nokogiri::HTML.parse(h)
    expect(doc.css('blockquote[type=cite]').size).to eq 0
    expect(doc.at_css('img')['src']).to eq 'cid:07654E88-C035-45AC-B0CC-A146E641DB4A'
  end

  it 'default .griddler_quote reply part' do
    allow(subject).to receive(:email_client).and_return(:default)
    origin = Nokogiri::HTML.parse(iphone)
    quote  = origin.css('blockquote[type=cite]')
    quote.attr('type').remove
    quote.attr('class', 'm_-1246824862396747064m_6843455178785846608griddler_quote')
    expect(quote.css('blockquote[class*=griddler_quote]').size).to eq 1
    h   = subject.extract_reply_html(origin.to_s, nil)
    doc = Nokogiri::HTML.parse(h)
    expect(doc.css('blockquote[class*=griddler_quote]').size).to eq 0
    expect(doc.at_css('img')['src']).to eq 'cid:07654E88-C035-45AC-B0CC-A146E641DB4A'
  end

  #[x] 1 Apple iPhone 33% -0.76
  #[x] 2 Gmail 19% +1.6
  #[ ] 3 Apple iPad 12% +0.17
  #[ ] 4 Google Android 8% +0.07
  #[x] 5 Apple Mail 7% -0.36
  #[ ] 6 Outlook 6% -0.47
  #[x] 7 Outlook.com 5% -0.23

  context '#email_client' do
    it 'outlook_web' do
      headers = { 'Message-Id' => '259F7F7C-7374-4D7C-913A-E15B411D033A@prod.outlook.com' }
      expect(Griddler::EmailParser.email_client(headers)).to eq :outlook_web
    end

    it 'outlook_mac' do
      headers = { 'Message-Id' => '259F7F7C-7374-4D7C-913A-E15B411D033A@gmail.com', 'User-Agent' => 'Microsoft-MacOutlook/f.18.0.160709' }
      expect(Griddler::EmailParser.email_client(headers)).to eq :outlook_mac
    end

    it 'gmail' do
      headers = { 'Message-Id' => '259F7F7C-7374-4D7C-913A-E15B411D033A@mail.gmail.com' }
      expect(Griddler::EmailParser.email_client(headers)).to eq :gmail
    end

    it 'icloud' do
      headers = { 'Message-Id' => '259F7F7C-7374-4D7C-913A-E15B411D033A@icloud.com' }
      expect(Griddler::EmailParser.email_client(headers)).to eq :icloud
    end
  end
end