Griddler
========

[![Build Status](https://travis-ci.org/thoughtbot/griddler.png?branch=master)](https://travis-ci.org/thoughtbot/griddler)
[![Code Climate](https://codeclimate.com/github/thoughtbot/griddler.png)](https://codeclimate.com/github/thoughtbot/griddler)

### Receive emails in your Rails app

Griddler is a Rails engine that provides an endpoint for the
[SendGrid](http://sendgrid.com/docs/API%20Reference/Webhooks/parse.html),
[Cloudmailin](http://cloudmailin.com),
[Postmark](http://developer.postmarkapp.com/developer-inbound-parse.html),
[Mandrill](http://help.mandrill.com/entries/21699367-Inbound-Email-Processing-Overview), or
[Mailgun](http://documentation.mailgun.com/user\_manual.html#receiving-messages-via-http-through-a-forward-action)
parse APIs that hands off a built email object to a class implemented by you.

Tutorials
---------

* SendGrid wrote a
  [great tutorial](http://blog.sendgrid.com/receiving-email-in-your-rails-app-with-griddler/)
  on integrating Griddler with your application.
* We have our own blog post on the subject over at
  [Giant Robots](http://robots.thoughtbot.com/post/42286882447/handle-incoming-email-with-griddler).

Installation
------------

1. Add `griddler` and an [adapter] gem to your application's Gemfile
   and run `bundle install`.

   [adapter]: #adapters

2. A route is needed for the endpoint which receives `POST` messages. To add the
   route, in `config/routes.rb` you may either use the provided routing method
   `mount_griddler` or set the route explicitly. Examples:

   ```ruby
   # config/routes.rb

   # mount using default path: /email_processor
   mount_griddler

   # mount using a custom path
   mount_griddler('/email/incoming')

   # the DIY approach:
   post '/email_processor' => 'griddler/emails#create'
   ```

### Configuration Options

An initializer can be created to control some of the options in Griddler.
Defaults are shown below with sample overrides following. In
`config/initializers/griddler.rb`:

```ruby
Griddler.configure do |config|
  config.processor_class = EmailProcessor # CommentViaEmail
  config.processor_method = :process # :create_comment (A method on CommentViaEmail)
  config.to = :hash # :full, :email, :token
  config.cc = :email # :full, :hash, :token
  config.from = :email # :full, :token, :hash
  # :raw    => 'AppName <s13.6b2d13dc6a1d33db7644@mail.myapp.com>'
  # :email  => 's13.6b2d13dc6a1d33db7644@mail.myapp.com'
  # :token  => 's13.6b2d13dc6a1d33db7644'
  # :hash   => { raw: [...], email: [...], token: [...], host: [...], name: [...] }
  config.reply_delimiter = '-- REPLY ABOVE THIS LINE --'
  config.email_service = :sendgrid # :cloudmailin, :postmark, :mandrill, :mailgun
end
```

| Option             | Meaning
| ------             | -------
| `processor_class`  | The class Griddler will use to handle your incoming emails.
| `processor_method` | The method Griddler will call on the processor class when handling your incoming emails.
| `reply_delimiter`  | The string searched for that will split your body.
| `email_service`    | Tells Griddler which email service you are using. The supported email service options are `:sendgrid` (the default), `:cloudmailin` (expects multipart format), `:postmark` and `:mandrill`. You will also need to have an appropriate [adapter] gem included in your Gemfile.
| `to`, `config.cc` and `config.from` | The format of the returned value for that address in the email object. `:hash` will return all options within a -- (surprise!) -- hash.

By default Griddler will look for a class named `EmailProcessor` with a class
method named `process`, taking in one argument, a `Griddler::Email` instance
representing the incoming email.  For example, in `./lib/email_processor.rb`:

```ruby
class EmailProcessor
  def self.process(email)
    # all of your application-specific code here - creating models,
    # processing reports, etc
  end
end
```

Griddler::Email attributes
--------------------------

| Attribute      | Description
| -------------- | -----------
| `#to`          | An array of hashes containing recipient address information.  See [Email Addresses](#email-addresses) for more information.
| `#from`        | A hash containing the sender address information.
| `#cc`          | An array of hashes containing cc email address information.
| `#subject`     | The subject of the email message.
| `#body`        | The full contents of the email body **unless** there is a line in the email containing the string `-- Reply ABOVE THIS LINE --`. In that case `.body` will contain everything before that line.
| `#raw_text`    | The raw text part of the body.
| `#raw_html`    | The raw html part of the body.
| `#raw_body`    | The raw body information provided by the email service.
| `#attachments` | An array of `File` objects containing any attachments.
| `#headers`     | A hash of headers parsed by `Mail::Header`.
| `#raw_headers` | The raw headers included in the message.

### Email Addresses

Gridder::Email provides email addresses as hashes. Each hash will have the following
information of each recipient:

| Key | Value
| --- | -----
| `:token` | All the text before the email's "@". We've found that this is the most often used portion of the email address and consider it to be the token we'll key off of for interaction with our application.
| `:host` | All the text after the email's "@". This is important to filter the recipients sent to the application vs emails to other domains. More info below on the Upgrading to 0.5.0 section.
| `:email` | The email address of the recipient.
| `:full` | The whole recipient field (e.g., `Some User <hello@example.com>`).
| `:name` | The name of the recipient (e.g., `Some User`).

Testing In Your App
-------------------

You may want to create a factory for when testing the integration of Griddler
into your application. If you're using factory\_girl this can be accomplished
with the following sample factory:

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
        tempfile: File.new("#{File.expand_path(File.dirname(__FILE__))}/fixtures/img.png")
      })
    ]}
  end
end
```

Bear in mind, if you plan on using the `:with_attachment` trait, that this
example assumes your factories are in `spec/factories.rb` and you have
an image file in `spec/fixtures/`.

To use it in your tests, build with `email = build(:email)`
or `email = build(:email, :with_attachment)`.

Adapters
--------

Depending on the service you want to use Griddler with, you'll need to add an
adapter gem in addition to `griddler`.

| Service     | Adapter
| -------     | -------
| sendgrid    | [griddler-sendgrid]

[griddler-sendgrid]: https://github.com/thoughtbot/griddler-sendgrid

Writing an Adapter
------------------

Griddler can theoretically work with any email => POST service. In order to work
correctly, adapters need to have their POST parameters restructured.

`Griddler::Email` expects certain parameters to be in place for proper parsing
to occur. When writing an adapter, ensure that the `normalized_params` method of
your adapter returns a hash with these keys:

| Parameter      | Contents
| ---------      | --------
| `:to`          | The recipient field
| `:from`        | The sender field
| `:subject`     | Email subject
| `:text`        | The text body of the email
| `:html`        | The html body of the email, nil or empty string if not present
| `:attachments` | Array of attachments to the email. Can be an empty array.
| `:headers`     | The raw headers of the email. **Optional**.
| `:charsets`    | A JSON string containing the character sets of the fields extracted from the message. **Optional**.

All keys are required unless otherwise stated.

Adapters should be provided as gems. If you write an adapter, let us know and we
will add it to this README. See [griddler-sendgrid] for an example
implementation.

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
* [Mailgun Docs](http://documentation.mailgun.com/user\_manual.html#receiving-forwarding-and-storing-messages)

Credits
-------

Griddler was written by Caleb Thompson and Joel Oliveira.

Large portions of the codebase were extracted from thoughtbot's
[Trajectory](http://www.apptrajectory.com).

Thanks to our [contributors](https://github.com/thoughtbot/griddler/contributors)!

![thoughtbot](http://thoughtbot.com/images/tm/logo.png)

The names and logos for thoughtbot are trademarks of thoughtbot, inc.
