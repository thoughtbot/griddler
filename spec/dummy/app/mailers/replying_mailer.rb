require 'griddler/reply_mixin'

class ReplyingMailer < ActionMailer::Base
  include Griddler::ReplyMixin

  default from: 'info@myapp.example.com'

  def response(email)
    reply(email) do |format|
      format.text { render text: 'The text version of the email!' }
      format.html
    end
  end
end
