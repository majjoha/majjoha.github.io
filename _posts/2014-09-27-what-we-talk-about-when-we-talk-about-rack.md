---
layout: post
title:  "What We Talk About When We Talk About Rack"
date:   2014-09-27
---

I was encouraged by [Jamie Hodge](https://twitter.com/jamiemhodge) to give a
talk at this week's [Copenhagen Ruby Brigade](http://www.copenhagenrb.dk/) meetup
about Rack, and in this post, I'd like to give a recap on the subject.

[Rack](https://github.com/rack/rack) is essentially a minimal web server
interface that [Rails](http://rubyonrails.org/),
[Sinatra](http://www.sinatrarb.com/), [Lotus](http://lotusrb.org/),
[Cuba](http://cuba.is/), [Camping](https://github.com/camping/camping) and
friends all heavily rely on. They do so in order not to interact directly with
the lower levels of the socket communication, and instead they distribute this
particular work for Rack, so they can focus on other parts of the architecture.
The main benefit of Rack is that you can write your applications once, and run
them everywhere.  Almost all Ruby servers support Rack, so you can easily power
up your application without having to tailor it to a specific platform.

A Rack application is basically an object that responds to `#call`, accepts
`env` as its only argument and returns an array containing the HTTP status code,
the headers and an object that responds to `#each`. Using a stabby lambda, a
simple Rack application printing "Hello, world" to its users could look like
this:

```ruby
require 'rack'
app = ->(env) do
  [200, {"Content-type" => "text/html"}, ["<h1>Hello, world!</h1>"]]
end
Rack::Server.start(app: app)
```

At some point, we probably want to extract our logic into its own class. This is
quite manageable to do, since we simply need an object that responds to `#call`
and takes `env` as its only argument. We could for instance end up with the
following:

```ruby
require 'rack'
class SuperAdvancedWebApp
  def call(env)
    [200, {"Content-type" => "text/html"}, [env]]
  end
end
Rack::Server.start(app: SuperAdvancedWebApp.new)
```

Except from being extracted into a class, the aforementioned application is
slightly different in that it actually returns the result of the `env` to its
visitors, so that we can investigate the contents of the current environment
from the browser.

For learning purposes, I've built a small web framework utilizing Rack that
discovers how we can effortlessly build a framework similar to Rails, Sinatra
and so forth which I've named Dolphy, and you can study the source code on
[GitHub](https://github.com/majjoha/dolphy).

It is possible to avoid the dependency of Rack by using TCP sockets as I
presented in my previous post, "[Investigating
sockets](/2014/09/17/investigating-sockets/)". The incredibly small framework
[busker](https://github.com/pachacamac/busker) is an attempt at building a web
framework without the dependency of Rack. I keep a branch called
[majjoha/rackless](https://github.com/majjoha/dolphy/tree/majjoha/rackless) in
the Dolphy repository where I try to remove Rack from the dependencies of the
project in a similar manner.

Furthermore, Rack itself is also in an exciting state at this moment, as [Aaron
Patterson](https://twitter.com/tenderlove) who is also a Rails core contributor
recently took over the development of the project. This is what he said about
the `env` hash back in August:

<blockquote class="twitter-tweet" data-conversation="none" lang="en"><p><a href="https://twitter.com/jcoglan">@jcoglan</a> not just that, the mutable env hash passed everywhere is the bane of my existence.</p>&mdash; Aaron Patterson (@tenderlove) <a href="https://twitter.com/tenderlove/status/502479098975764480">August 21, 2014</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

I am thrilled to see that we'll finally get rid of the `env` hash from our Rack
applications. In the repository,
[the_metal](https://github.com/tenderlove/the_metal), he keeps a spike for
thoughts about Rack 2.0, and according to the examples in the project, it'll
slightly change how we use Rack to build our web applications:

```ruby
class Application
  def call req, res
    res.write_head 200, 'Content-Type' => 'text/plain'
    res.write "Hello World\n"
    res.finish
  end
end
require 'the_metal/puma'
server = TheMetal.create_server Application.new
server.listen 9292, '0.0.0.0'
```

I highly welcome the change, and I find this new way of interacting with the
request and response directly much more elegant than fiddling with the `env`
hash as we're used to. It is going to be interesting to see how these changes
will affect all the existing frameworks that we use today.
