require "html/proofer"

IGNORE_LINKS = [
  "http://localhost:2345"
]

task(:test) do
  sh "bundle exec jekyll build"
  HTML::Proofer.new(
    "./public",
    href_ignore: IGNORE_LINKS,
    typhoeus: {
      headers: {
        "User-Agent" => "Mozilla/5.0 (compatible; My New User-Agent)"
      }
    }
  ).run
end

task(default: :test)
