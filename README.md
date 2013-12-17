Griddler
========

[![Build Status](https://travis-ci.org/thoughtbot/griddler.png?branch=master)](https://travis-ci.org/thoughtbot/griddler)
[![Code Climate](https://codeclimate.com/github/thoughtbot/griddler.png)](https://codeclimate.com/github/thoughtbot/griddler)

### Receive emails in your Rails app

Griddler is a Rails engine (full plugin) that provides an endpoint for the
[SendGrid parse api](http://sendgrid.com/docs/API%20Reference/Webhooks/parse.html),
[Cloudmailin parse api](http://cloudmailin.com),
[Postmark parse api](http://developer.postmarkapp.com/developer-inbound-parse.html) or
[Mandrill parse api](http://help.mandrill.com/entries/21699367-Inbound-Email-Processing-Overview)
[Mailgun routes](http://documentation.mailgun.com/user_manual.html#receiving-messages-via-http-through-a-forward-action)
that hands off a built email object to a class implemented by you.

Tutorials
---------

* SendGrid has done a
  [great tutorial](http://blog.sendgrid.com/receiving-email-in-your-rails-app-with-griddler/)
  on integrating Griddler with your application.
* And of course, view our own blog post on the subject over at
  [Giant Robots](http://robots.thoughtbot.com/post/42286882447/handle-incoming-email-with-griddler).

Installation
------------

Add griddler to your application's Gemfile and run `bundle install`:

```ruby
gem 'griddler'
```
A route is needed for the endpoint which receives `POST` messages. Currently,
the route is automatically appended to the route table like so:

```ruby
email_processor POST /email_processor(.:format)   griddler/emails#create
```

**NOTE: This behavior is deprecated and will be removed by version 0.7.0 in favor
of manually adding the route.**

To manually add the route, in `config/routes.rb` you may either use the provided
routing method `mount_griddler` or set the route explicitly. Examples:

```ruby
# mount using default path
mount_griddler

# mount using a custom path
mount_griddler('/email/incoming')

# the "get off my lawn", DIY approach:
post '/email_processor' => 'griddler/emails#create'
```

Defaults
--------

By default Griddler will look for a class to be created in your application
called EmailProcessor with a class method implemented, named process, taking
in one argument (presumably `email`). For example, in `./lib/email_processor.rb`:

```ruby
class EmailProcessor
  def self.process(email)
    # all of your application-specific code here - creating models,
    # processing reports, etc
  end
end
```

The contents of the `email` object passed into your process method is an object
that responds to:

* `.to`
* `.from`
* `.cc`
* `.subject`
* `.body`
* `.raw_text`
* `.raw_html`
* `.raw_body`
* `.attachments`
* `.headers`
* `.raw_headers`

Each of those has some sensible defaults.

`.raw_body`, `.raw_headers`, and `.subject` will contain the obvious
values found in the email, the raw values from those fields.

`.body` will contain the full contents of the email body **unless** there is a
line in the email containing the string `-- Reply ABOVE THIS LINE --`. In that
case `.body` will contain everything before that line.

`.to` will contain an array of hashes. Each hash will have the following
information of each recipient:

  * `token`: All the text before the email's "@". We've found that this is the
  most often used portion of the email address and consider it to be the token
  we'll key off of for interaction with our application.

  * `host`: All the text after the email's "@". This is important to filter
  the recipients sent to the application vs emails to other domains. More
  info below on the Upgrading to 0.5.0 section.

  * `email`: The email address of the recipient.

  * `full`: The whole recipient field. E.g, `Some User <hello@example.com>`
  * `name`: The name of the recipient. E.g, `Some User`

`.from` will default to the `email` value of a hash like `.to`, and can be
configured to return the full hash.

`.cc` will be an array of the addresses in the Cc header, with an empty array
if no addresses were present.

`.attachments` will contain an array of attachments as multipart/form-data files
which can be passed off to attachment libraries like Carrierwave or Paperclip.

`.headers` will contain a hash of header names and values as parsed by the Mail
gem. Headers will only be parsed if the adapter supports a headers option.

Configuration Options
---------------------

An initializer can be created to control some of the options in Griddler. Defaults
are shown below with sample overrides following. In `config/initializers/griddler.rb`:

```ruby
Griddler.configure do |config|
  config.processor_class = EmailProcessor # MyEmailProcessor
  config.processor_method = :process # :custom_method
  config.to = :hash # :full, :email, :token
  config.from = :email # :full, :token, :hash
  # :raw    => 'AppName <s13.6b2d13dc6a1d33db7644@mail.myapp.com>'
  # :email  => 's13.6b2d13dc6a1d33db7644@mail.myapp.com'
  # :token  => 's13.6b2d13dc6a1d33db7644'
  # :hash   => { raw: [...], email: [...], token: [...], host: [...],
name: [...] }
  config.reply_delimiter = '-- REPLY ABOVE THIS LINE --'
  config.email_service = :sendgrid # :cloudmailin, :postmark, :mandrill, :mailgun
end
```

* `config.processor_class` is the class Griddler will use to handle your incoming emails.
* `config.processor_method` is the method Griddler will call on the processor class when handling your incoming emails.
* `config.reply_delimiter` is the string searched for that will split your body.
* `config.to` and `config.from` are the format of the returned value for that
  address in the email object. `:hash` will return all options within a -- (surprise!) -- hash.
* `config.email_service` tells Griddler which email service you are using. The
  supported email service options are `:sendgrid` (the default), `:cloudmailin`
  (expects multipart format), `:postmark` and `:mandrill`.

Testing In Your App
-------------------

You may want to create a factory for when testing the integration of Griddler into
your application. If you're using factory\_girl this can be accomplished with the
following sample factory.

```ruby
factory :email, class: OpenStruct do
  # Assumes Griddler.configure.to is :hash (default)
  to [{ full: 'to_user@email.com', email: 'to_user@email.com', token: 'to_user', host: 'email.com', name: nil }]
  from 'user@email.com'
  subject 'email subject'
  body 'Hello!'
  attachments {[]}

  trait :with_attachment do
    attachments {[
      ActionDispatch::Http::UploadedFile.new({
        filename: 'img.png',
        type: 'image/png',
        tempfile: File.new("#{File.expand_path File.dirname(__FILE__)}/fixtures/img.png")
      })
    ]}
  end
end
```

Bear in mind, if you plan on using the `:with_attachment` trait, that this
example assumes your factories are in `spec/factories.rb` and you have
an image file in `spec/fixtures/`.

To use it in your test(s) just build with `email = build(:email)`
or `email = build(:email, :with_attachment)`.

Adapters
--------

`Griddler::Email` expects certain parameters to be in place for proper parsing
to occur. When writing an adapter, ensure that the `normalized_params` method
of your adapter returns a hash with these keys:

* `:to` The recipient field
* `:from` The sender field
* `:subject` Email subject
* `:text` The text body of the email
* `:html` The html body of the email, nil or empty string if not present
* `:attachments` (can be an empty array) Array of attachments to the email
* `:headers` (optional) The raw headers of the email
* `:charsets` (optional) A JSON string containing the character sets of the
  fields extracted from the message

Upgrading to Griddler 0.5.0
---------------------------

Because of an issue with the way Griddler handled recipients in the `To` header,
a breaking change was introduced in Griddler 0.5.0 that requires a minor change
to `EmailProcessor` or `processor_class`.

Previously, a single address was returned from `Griddler::Email#to`. Moving
forward, this field will always be an array. Generally speaking, you will want
to do something like this to handle the change:

```ruby
# before
def initialize(email)
  @to = email.to
  @from = email.from
  @body = email.body
end

# after
def initialize(email)
  @to = pick_meaningful_recipient(email.to)
  @from = email.from
  @body = email.body
end

private

def pick_meaningful_recipient(recipients)
  recipients.find { |address| address =~ /@mydomain.com$/ }
end
```

Using Griddler with Mandrill
----------------------------

When adding a webhook in their administration panel, Mandrill will issue a HEAD
request to check if the webhook is valid (see
[Adding Routes](http://help.mandrill.com/entries/21699367-Inbound-Email-Processing-Overview)).
If the HEAD request fails, Mandrill will not allow you to add the webhook.
Since Griddler is only configured to handle POST requests, you will not be able
to add the webhook as-is. To solve this, add a temporary route to your
application that can handle the HEAD request:

```ruby
# routes.rb
get "/email_processor", to: proc { [200, {}, ["OK"]] }, as: "mandrill_head_test_request"
```

Once you have correctly configured Mandrill, you can go ahead and delete this code.

More Information
----------------

* [SendGrid](http://www.sendgrid.com)
* [SendGrid Parse API](http://www.sendgrid.com/docs/API Reference/Webhooks/parse.html)
* [Cloudmailin](http://cloudmailin.com)
* [Cloudmailin Docs](http://docs.cloudmailin.com/)
* [Postmark](http://postmarkapp.com)
* [Postmark Docs](http://developer.postmarkapp.com/)
* [Mandrill](http://mandrill.com)
* [Mandrill Docs](http://help.mandrill.com/forums/21092258-Inbound-Email-Processing)
* [Mailgun](http://mailgun.com)
* [Mailgun Docs](http://documentation.mailgun.com/user_manual.html#receiving-forwarding-and-storing-messages)

Credits
-------

Griddler was written by Caleb Thompson and Joel Oliveira.

Large portions of the codebase were extracted from thoughtbot's
[Trajectory](http://www.apptrajectory.com).

![thoughtbot](http://thoughtbot.com/images/tm/logo.png)

The names and logos for thoughtbot are trademarks of thoughtbot, inc.

License
-------

Griddler is Copyright © 2013 Caleb Thompson, Joel Oliveira and thoughtbot. It is
free software, and may be redistributed under the terms specified in the LICENSE
file.
