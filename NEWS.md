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
