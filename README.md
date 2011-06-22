# EM-APN - EventMachine'd Apple Push Notifications #

We want:

 * Streamlined for a persistent connection use-case
 * Support for the enhanced protocol, with receipts

## Usage ##

A simple interface is provided to just fire and forget:

    require "em-apn"

    EM.run do
      EM::APN.push(token, :alert => "Hello world")
    end

Using this interface, you need to set some environment variables so that EM::APN
can find your SSL certificates:

    ENV["APN_KEY"]  = "/path/to/key.pem"
    ENV["APN_CERT"] = "/path/to/cert.pem"

Also, by default, the library connects to Apple's sandbox push server. If you want
to connect to the production server, simply set the `APN_ENV` environment variable
to `production`:

    ENV["APN_ENV"] = "production"

And yes, it's environment variable heavy since this is originally destined for
Heroku. The simple interface takes care of setting up and re-using a single,
persistent connection to Apple's servers, but doesn't give you a way to setup
callbacks for any replies. For that level of control, use the EM::APN::Client
class directly.

    EM.run do
      @client = EM::APN::Client.connect(
        :host => "gateway.push.apple.com",
        :port => 2195,
        :key  => "/path/to/key.pem",
        :cert => "/path/to/cert.pem"
      )
      @client.on_receipt do |data|
        # Do something
      end

      # In some other callback
      notification = EM::APN::Notification.new(token, :alert => "Hello world")
      @client.deliver(notification)
    end

In this example, we're explicitly setting the host, port, key, and cert with
options to `APN::Client.connect`, but the environment variables mentioned above will
work as well.

## Caveats ##

Currently, if the connection goes down, any deliveries that are attempted will
be black-holed. The dropped connection will attempt to reconnect on an
exponential decay, but keep this in mind. Future work will attempt to remedy
this by returning some kind of error from `APN.push` and `APN::Client.deliver`,
or queueing up failed deliveries for retry later.

## TODO ##

 * Support the feedback API for dead tokens
 * Handle deliveries when the connection goes down

## Inspiration ##

Much thanks to:

 * https://github.com/kdonovan/apn_sender
 * http://blog.technopathllc.com/2010/12/apples-push-notification-with-ruby.html
