require "html/proofer"

IGNORE_LINKS = [
  "http://localhost:2345",
  "http://linkedin.com/in/majjoha"
]

task(:test) do
  sh "bundle exec jekyll build"
  HTML::Proofer.new("./public", href_ignore: IGNORE_LINKS).run
end

task(default: :test)
