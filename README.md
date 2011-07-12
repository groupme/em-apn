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

Using this interface, the easiest way to configure the connection is by setting
some environment variables so that EM::APN can find your SSL certificates:

    ENV["APN_KEY"]  = "/path/to/key.pem"
    ENV["APN_CERT"] = "/path/to/cert.pem"

Also, by default, the library connects to Apple's sandbox push server. If you
want to connect to the production server, simply set the `APN_ENV`
environment variable to `production`:

    ENV["APN_ENV"] = "production"

This simple interface takes care of setting up and re-using a single,
persistent connection to Apple's servers, and re-connects on demand if the
connection is dropped.

It's also possible to create a connection manually, and currently, this is
the only option if you want to attach a callback for data returned by Apple:

    EM.run do
      @client = EM::APN::Client.connect(
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

In this example, we're explicitly setting the key, and cert with options to
`APN::Client.connect`, but the environment variables mentioned above will
work as well. Please keep in mind that Apple will close the connection
whenever an error is returned, and `APN::Client.closed?` should be polled to
check for disconnects.

### Max Payload Size ###

Apple enforces a limit of __256 bytes__ for the __entire payload__.

We raise an `EM::APN::Notification::PayloadTooLarge` exception.

How you truncate your payloads is up to you. Be especially careful when dealing with multi-byte data.

## TODO ##

 * Support the feedback API for dead tokens

## Inspiration ##

Much thanks to:

 * https://github.com/kdonovan/apn_sender
 * http://blog.technopathllc.com/2010/12/apples-push-notification-with-ruby.html
