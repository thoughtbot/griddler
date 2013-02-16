# Contributing

We love pull requests. Here's a quick guide:

1. Fork the repo.
2. Run the tests. We only take pull requests with passing tests, and it's great
   to know that you have a clean slate: `bundle && rake`
3. Add a test for your change. Only refactoring and documentation changes
   require no new tests. If you are adding functionality or fixing a bug, we need
   a test!
4. Make the test pass.
5. Make sure your changes adhere to the
   [thoughtbot Style Guide](https://github.com/thoughtbot/guides/tree/master/style)
6. Push to your fork and submit a pull request.
7. At this point you're waiting on us. We like to at least comment on, if not
   accept, pull requests within three business days (and, typically, one business
   day). We may suggest some changes or improvements or alternatives.

## Increase your chances of getting merged

Some things that will increase the chance that your pull request is accepted,
taken straight from the Ruby on Rails guide:

1. Use Rails idioms and helpers
2. Include tests that fail without your code, and pass with it
3. Update the documentation, the surrounding one, examples elsewhere, guides,
   whatever is affected by your contribution
4. Syntax:
   * Two spaces, no tabs.
   * No trailing whitespace. Blank lines should not have any space.
   * Prefer `&&`/`||`  over `and`/`or`.
   * `MyClass.my_method(my_arg)` not `my_method( my_arg )` or `my_method my_arg`.
   * `a = b` and not `a=b`.
   * Follow the conventions you see used in the source already.
5. And in case we didn't emphasize it enough: we love tests!
