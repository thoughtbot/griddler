## The griddler.io site

This is the source of http://griddler.io .

It's a Jekyll app running on GitHub pages.

## Local development

Watch sass:

    rake sass_watch

Run Jekyll, watching for changes:

    jekyll serve -w

Now visit http://localhost:4000.

To release a new version, first re-build the SCSS because GitHub won't do it for
you:

    rake build

Now commit the CSS file.
