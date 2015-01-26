desc "Watch SCSS files for changes"
task :sass_watch do
  `bundle exec sass --watch stylesheets/main.scss:stylesheets/main.css`
end

desc "Compile SCSS for a new release"
task :build do
  `sass stylesheets/main.scss:stylesheets/main.css`
end
