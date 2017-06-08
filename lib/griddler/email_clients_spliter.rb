module Griddler::EmailClientsSpliter
  class << self
    def outlook_web(doc)
      doc.at_css('body > #divtagdefaultwrapper').to_s
    end

    def outlook_mac(doc)
      doc.css('body > div > .MsoNormal,.MsoListParagraph').to_s
    end

    def gmail(doc)
      doc.at_css('body > .gmail_extra')&.remove
      doc.at_css('body > div > .gmail_extra')&.remove
      doc.at_css('body').inner_html
    end

    def icloud(doc)
      # Apple Mail
      doc.at_css('body > div > blockquote[type=cite]')&.remove
      # iPhone
      doc.at_css('body > blockquote[type=cite]')&.remove
      doc.at_css('body').inner_html
    end

    def default(doc)
      # 默认尝试清楚 <blockquote class='m_-1246_6843455griddler_quote'> 的元素
      doc.at_css('body > blockquote[class*=griddler_quote]')&.remove
      doc.to_s
    end
  end
end