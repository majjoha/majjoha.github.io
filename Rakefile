require "html-proofer"

IGNORE_LINKS = [
  "http://localhost:2345",
  "http://linkedin.com/in/majjoha",
  "https://www.react-europe.org",
  "https://elixir-lang.org"
]

task(:test) do
  sh "bundle exec jekyll build"
  HTMLProofer.check_directory(
    "./public",
    url_ignore: IGNORE_LINKS,
    assume_extension: true
  ).run
end

task(default: :test)
