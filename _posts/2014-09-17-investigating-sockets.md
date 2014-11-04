---
layout: post
title:  "Investigating Sockets"
date:   2014-09-17
---

During this summer, I've revisited an old side project of mine which is a
Ruby-based micro framework for web development. Like most web frameworks in
Ruby, this heavily depends on Rack which can be extremely helpful in a lot
of ways, but you do not learn all the lower levels of how the server handles
requests from clients and so forth that I find somewhat intriguing. This
ultimately led me to investigate the different sockets that the Ruby standard
library provides and in general improve my understanding on sockets. This post
covers some of my findings from the process.

Sockets are the endpoints of bidirectional communication channels. The Ruby
standard library has six different socket classes: `UNIXSocket`, `UDPSocket`,
`TCPSocket`, `Socket`, `IPSocket`, and they all inherit from the sixth socket
class `BasicSocket`. The class hierarchy for the sockets in Ruby looks like
this:

![Class hierarchy](/images/sockets-class-hierarchy.png)

Starting from the bottom, TCP is the most commonly used protocol on the Internet
as it offers error correction, and like UDP it belongs to the transport layer.
Furthermore, TCP sockets guarantee delivery which means that it will resend
packets if needed and stop the data flow until packets are successfully
transferred, so TCP sockets are considered very reliable.

Implementing a small single-threaded web server that prints the current time to
the user could be done this way utilizing the `TCPServer`.

<pre class="prettyprint">
require 'socket'

server = TCPServer.new('localhost', 2345)

loop do
  client = server.accept
  client.gets
  client.puts "Time is #{Time.now}"
  client.close
end
</pre>

Accessing [http://localhost:2345](http://localhost:2345) in the browser would
then return the current time to the user.  This is actually what I started out
with when I was replacing Rack with sockets, and from here you need to figure
out how to match URLs from the user, handle multiple users, send/receive POST
and GET parameters, send the necessary headers to the browser and so on. This
process reveals how much work Rack actually does for you, but I enjoy seeing how
much I can do without it as well.

Moving on to UDP, this protocol, on the other hand, is considered unreliable,
but it offers speed why it is often used for streaming purposes.  Also, UDP
packets are remarkably smaller than TCP packets. Unlike TCP, UDP does not
provide any error correction or flow control, so errors will be present.

Since UDP does not do retransmissions, we might also lose content, or content
might be ordered the wrong way as UDP does not guarantee in-order delivery.
Thus, TCP is quite obviously the most appropriate protocol of the two to rely on
when implementing a web framework without Rack.

Implementing a simple chat server and client using `UDPSocket` could be done the
following way:

<pre class="prettyprint">
# udp-server.rb
require 'socket'

socket = UDPSocket.new
socket.bind('localhost', 33333)

loop do
  data, address = socket.recvfrom(1024)
  puts "From address: '#{address.join(',')}', message: #{data}"
end

socket.close
</pre>

<pre class="prettyprint">
# udp-client.rb
require 'socket'

socket = UDPSocket.new

while message = gets.chomp
  socket.send(message, 0, '127.0.0.1', 33333)
end

socket.close
</pre>

The server creates a new `UDPSocket` and binds it to localhost on port 3333.
From here, it will simply run a loop listening for messages and print them.  The
client works in a similar fashion. It creates a new `UDPSocket`, runs a loop
that receives messages from the standard input which it then sends to our
server.

Moving up the class hierarchy, we have `UNIXSocket`, `IPSocket` and `Socket`
where the latter will not be elaborated. A `UNIXSocket` basically represents a
UNIX domain stream client, and what characterizes a UNIX domain stream is that
it does not use any underlying network protocol for communication, so it has
less overhead. It solely exists inside a single computer, and processes
communicating with a UNIX domain stream needs to be on the same computer too.
For these reasons, the `UNIXSocket` is obviously not suited for a web framework,
but the [`UnixSocketForker`](https://gist.github.com/ryanlecompte/1619490) by
Ryan LeCompte is an interesting usage of the `UNIXSocket` in a Ruby context.
Finally, the `IPSocket` which is also the superclass of `TCPSocket` and
`UDPSocket` is not so exciting on its own and therefore a little difficult to
leverage, but one common usage for the `IPSocket` is looking up the IP address
of the host which we could do in the following way:

<pre class="prettyprint">
require 'socket'

ip = IPSocket.getaddress(Socket.gethostname)
puts ip #=> "192.168.0.100"
</pre>

Investigating sockets have been an interesting journey so far, and I'll
certainly need to investigate them even more for this project in particular. I
hope you've found this whirlwind tour of the Ruby sockets useful, and feel free
to ping me if you've any questions.
