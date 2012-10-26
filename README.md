`config/initializer/griddler.rb`

```
Griddler.setup do |config|
#  config.handler_class = EmailProcessor
#  config.handler_method = :go
#  config.raw_body = false # true
#  config.to = :raw || :email || :token || :hash
#    :raw => 'AppName <s13.6b2d13dc6a1d33db7644@mail.myapp.com>'
#    :email => 's13.6b2d13dc6a1d33db7644@mail.myapp.com'
#    :token => 's13.6b2d13dc6a1d33db7644'
#    :hash => { raw: '', email: '', token: '', host: '' }
#  config.reply_delimeter = '-- REPLY ABOVE THIS LINE --'
end
```


`lib/email_processor.rb`

```
class EmailProcessor
  def go(email)
    # to = email[:to]
    # from = email[:from]
    # subject = email[:subject]
    # body = email[:body]
    # attachments = email[:attachments]
  end
end
```
