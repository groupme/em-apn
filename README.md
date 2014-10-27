# EM-APN - EventMachine'd Apple Push Notifications #

We want:

 * Streamlined for a persistent connection use-case
 * Support for the enhanced protocol, with receipts

## Usage ##

In a nutshell:

    require "em-apn"

    # Inside a reactor...
    notification = EM::APN::Notification.new(token, :alert => alert)
    client = EM::APN::Client.connect
    client.deliver(notification)

Using this interface, the easiest way to configure the connection is by setting
some environment variables so that EM::APN can find your SSL certificates:

    ENV["APN_KEY"]  = "/path/to/key.pem"
    ENV["APN_CERT"] = "/path/to/cert.pem"

Also, by default, the library connects to Apple's sandbox push server. If you
want to connect to the production server, simply set the `APN_ENV`
environment variable to `production`:

    ENV["APN_ENV"] = "production"

The gateway and SSL certs can also be set directly when instantiating the object:

    client = EM::APN::Client.connect(
      :gateway => "some.host",
      :key     => "/path/to/key.pem",
      :cert    => "/path/to/cert.pem"
    )

The client manages an underlying `EM::Connection`, and it will automatically
reconnect to the gateway when the connection is closed. Callbacks can be set
on the client to handle error responses from the gateway, connection open & close
events:

    client = EM::APN::Client.connect
    client.on_error do |response|
      # See EM::APN::ErrorResponse
    end

    client.on_close do
      # Do something.
    end

    client.on_open do
      # Do something
    end

In our experience, we've found that Apple immediately closes the connection
whenever an error is detected, so the error and close callbacks are nearly
always called one-to-one. These methods exist as a convenience, and the
callbacks can also be set directly to anything that responds to `#call`:

    client.error_callback = Proc.new { |response| ... }
    client.close_callback = Proc.new { ... }
    client.open_callback  = Proc.new { ... }

### Max Payload Size ###

Apple enforces a limit of __2048 bytes__ for the __entire payload__.

If you attempt to deliver a notification that exceeds that limit, the library
will raise an `EM::APN::Notification::PayloadTooLarge` exception.

To prevent that from happening, you can call `#truncate_alert!` on the
notification.

    notification = EM::APN::Notification.new(...)
    notification.truncate_alert!
    client.deliver(notification)

## Inspiration ##

Much thanks to:

 * https://github.com/kdonovan/apn_sender
 * http://blog.technopathllc.com/2010/12/apples-push-notification-with-ruby.html
