Griddler
========

[![Build Status](https://travis-ci.org/thoughtbot/griddler.png?branch=master)](https://travis-ci.org/thoughtbot/griddler)
[![Code Climate](https://codeclimate.com/github/thoughtbot/griddler.png)](https://codeclimate.com/github/thoughtbot/griddler)

### Receive emails in your Rails app

Griddler is a Rails engine (full plugin) that provides an endpoint for the
[SendGrid parse api](http://sendgrid.com/docs/API%20Reference/Webhooks/parse.html),
[Cloudmailin parse api](http://cloudmailin.com) or
[Postmark parse api](http://developer.postmarkapp.com/developer-inbound-parse.html)
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

Griddler comes with a default endpoint that will be displayed at the bottom
of the output of `rake routes`. If there is a previously defined route that
matches `/email_processor` -- or you would like to rename the matched path -- you
may add the route to the desired position in routes.rb with the following:

```ruby
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
* `.subject`
* `.body`
* `.raw_body`
* `.attachments`
* `.headers`
* `.raw_headers`

Each of those has some sensible defaults.

`.from`, `.raw_body`, `.raw_headers`, and `.subject` will contain the obvious
values found in the email, the raw values from those fields.

`.body` will contain the full contents of the email body **unless** there is a
line in the email containing the string `-- Reply ABOVE THIS LINE --`. In that
case `.body` will contain everything before that line.

`.to` will contain all of the text before the email's "@" character. We've found
that this is the most often used portion of the email address and consider it to
be the token we'll key off of for interaction with our application.

`.attachments` will contain an array of attachments as multipart/form-data files
which can be passed off to attachment libraries like Carrierwave or Paperclip.

`.headers` will contain a hash of header names and values as parsed by the Mail
gem. Headers will only be parsed if the adapter supports a headers option.

Configuration Options
---------------------

An initializer can be created to control some of the options in Griddler. Defaults
are shown below with sample overrides following. In `config/initializer/griddler.rb`:

```ruby
Griddler.configure do |config|
  config.processor_class = EmailProcessor # MyEmailProcessor
  config.to = :token # :raw, :email, :hash
  # :raw    => 'AppName <s13.6b2d13dc6a1d33db7644@mail.myapp.com>'
  # :email  => 's13.6b2d13dc6a1d33db7644@mail.myapp.com'
  # :token  => 's13.6b2d13dc6a1d33db7644'
  # :hash   => { raw: '', email: '', token: '', host: '' }
  config.reply_delimiter = '-- REPLY ABOVE THIS LINE --'
  config.email_service = :sendgrid
end
```

* `config.processor_class` is the class Griddler will use to handle your incoming emails.
* `config.reply_delimiter` is the string searched for that will split your body.
* `config.to` is the format of the returned value for the `:to` key in
the email object. `:hash` will return all options within a -- (surprise!) -- hash.
* `config.email_service` tells Griddler which email service you are using. The supported
email service options are :sendgrid (the default), :cloudmailin (expects
multipart format) and :postmark

Testing In Your App
-------------------

You may want to create a factory for when testing the integration of Griddler into
your application. If you're using factory_girl this can be accomplished with the
following sample factory.

```ruby
factory :email, class: OpenStruct do
  to 'email-token'
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

More Information
----------------

* [SendGrid](http://www.sendgrid.com)
* [SendGrid Parse API](http://www.sendgrid.com/docs/API Reference/Webhooks/parse.html)
* [Cloudmailin](http://cloudmailin.com)
* [Cloudmailin Docs](http://docs.cloudmailin.com/)
* [Postmark](http://postmarkapp.com)
* [Postmark Docs](http://developer.postmarkapp.com/)

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
