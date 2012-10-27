`config/initializer/griddler.rb`

```
require 'email_processor'

Griddler.configure do |config|
#  config.handler_class = EmailProcessor
#  config.handler_method = :process
#  config.raw_body = false # true
#  config.reply_delimeter = '-- Reply ABOVE THIS LINE --'
#  config.to = :token || :raw || :email || :hash
#    :raw => 'AppName <s13.6b2d13dc6a1d33db7644@mail.myapp.com>'
#    :email => 's13.6b2d13dc6a1d33db7644@mail.myapp.com'
#    :token => 's13.6b2d13dc6a1d33db7644'
#    :hash => { raw: '', email: '', token: '', host: '' }
end
```


`lib/email_processor.rb`

```
class EmailProcessor
  def process(email)
    # to = email[:to]
    # from = email[:from]
    # subject = email[:subject]
    # body = email[:body]
    # attachments = email[:attachments]
  end
end
```

rails g griddler:install # add email processor class to lib/ & add require to
