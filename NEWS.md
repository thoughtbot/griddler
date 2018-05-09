## HEAD (unreleased)

## 1.5.2
* Add Email#charsets reader ([#292](https://github.com/thoughtbot/griddler/pull/292))

## 1.5.1
* Don't raise when skipping `verify_authenticity_token` ([#299](https://github.com/thoughtbot/griddler/pull/299))

## 1.5.0
* Add `params[:vendor_specific]` to `Griddler::Email` ([#285](https://github.com/thoughtbot/griddler/pull/285))
* Handle common French/Spanish formats ([#250](https://github.com/thoughtbot/griddler/pull/250))
* Add spam report and spam score to email ([#283](https://github.com/thoughtbot/griddler/pull/283))
* Pass original recipient and reply to through ([#271](https://github.com/thoughtbot/griddler/pull/271))
* Add license to gemspec ([#293](https://github.com/thoughtbot/griddler/pull/293))
* Add additional documentation to the `reply_delimiter` config field ([#294](https://github.com/thoughtbot/griddler/pull/294))
* Skip CSRF check in controller ([#298](https://github.com/thoughtbot/griddler/pull/298))
* Use RSpec request spec and test against Rails 5.1 ([#296](https://github.com/thoughtbot/griddler/pull/296]))
* Test against Rails 5.2 and Ruby 2.5. Drop testing against Ruby 2.1.

## 1.4.0
* Add `to_h` support to `Griddler::Email` ([#276](https://github.com/thoughtbot/griddler/pull/276))
* Allow user defined Email class ([#270](https://github.com/thoughtbot/griddler/pull/270))
* Handle gmail carriage returns ([#260](https://github.com/thoughtbot/griddler/pull/260))
* Fix link to SendGrid tutorial ([#259](https://github.com/thoughtbot/griddler/pull/259))
* Add reference to `griddler-ses` adapter to README.md ([#257](https://github.com/thoughtbot/griddler/pull/257))

## 1.3.1

* Allow access to email headers via an array ([#220](https://github.com/thoughtbot/griddler/issues/220))
* Fixes email address parsing when the email address may be blank ([#223](https://github.com/thoughtbot/griddler/issues/223))
* Add README link for SparkPost adapter ([#252](https://github.com/thoughtbot/griddler/issues/252))
* Handle "YYYY-MM-DD *" format ([#248](https://github.com/thoughtbot/griddler/issues/248))
* Set default configuration without a config file ([#228](https://github.com/thoughtbot/griddler/issues/228))
* Add split point for 3-line gmail inserts. ([#244](https://github.com/thoughtbot/griddler/issues/244), [#245](https://github.com/thoughtbot/griddler/issues/245))

## 1.3.0

* Make the code resilient against an empty recipient (#242)
* Make email_service, processor_method, processor_class private methods (#238)
* Clean invalid UTF-8 chars from the email subject (#230)
* The README claimed that the delimiter for replies was `-- REPLY ABOVE THIS
  LINE --`, but it was actually `-- Reply ABOVE THIS LINE --`. Now the
  delimiter is actually `-- REPLY ABOVE THIS LINE --`.

## 1.2.1

* Sanitize UTF-8 in addresses (#214, #215)
* Deep clean invalid UTF-8 bytes from header hash (#212)

## 1.2.0

* Use Ruby unicode compatible regexes for UTF8 strings (#208)
* Allow hashes to be submitted as headers (#185). Griddler will still clean the
  hash values of invalid UTF-8 bytes if you pass in hashes.
* Stop testing against Rails 4.0.x (#209)
* Test against Rails 4.2.x (#209)

## 1.1.1

* Clean non-UTF-8 chars from email headers (#84)

## 1.1.0

* Allow email body paragraphs to begin with 'On' (#74)
* Minor documentation fixes

## 1.0.0

* Convert test suite, including Griddler::Testing, to expect syntax for RSpec
  3.0 compliance. https://github.com/thoughtbot/griddler/pull/160

  *Peter Goldstein*

* Use instances of email processor classes rather than calling class methods.
  https://github.com/thoughtbot/griddler/pull/153

  *Caleb Thompson*
* Remove configuration of email addresses for to, from, and cc.
  https://github.com/thoughtbot/griddler/pull/150

  *Caleb Thompson*

* Update body parser regex to allow for new lines. d40bbf1

  *gust*
* Remove adapters, extract them to gems.

  *Caleb Thompson, Gabe Berke-Williams, Stafford Brunk, Brad Pauly*
* Move be_normalized_to matcher to Griddler::Testing. d1e879e

  *Caleb Thompson*
* griddler 1.0.0-alpha.2. 6be5e81

  *Caleb Thompson*
* Make README friendlier.

  *Caleb Thompson and Gabe Berke-Williams*
* Update to RSpec 3.0. 1b72814

  *Caleb Thompson*
* Remove generated email_processor route. 4a1fb50

  *Caleb Thompson*
* Remove 0.5.0 upgrade note from README.md. fb35ba6

  *Caleb Thompson*
* Rename RAILS_VERSION to RAILS_BRANCH. 1e380e5

  *Gabe Berke-Williams*
* Test against different Rails version on Travis. 2b4d484

  *Gabe Berke-Williams*
* Remove Rails deprecation messages in specs. 278955f

  *Gabe Berke-Williams*
* Better error for missing EmailProcessor. 2fedd2b

  *Caleb Thompson*
* Better handle `to` from Mailgun. e8fcdfc

  *Brad Pauly*
* Update supported versions to the latest in 2.0.\* and 2.1.\* for Ruby and
  Rails versions to latest in 4.0.\* and 4.1.\*. 53fb30b

  *Caleb Thompson*
