# Expo::Server::SDK

This gem was written because of the relatively little attention and improvement [expo-server-sdk-ruby](https://github.com/expo-community/expo-server-sdk-ruby) receives.

It does **not** work in the same way, so you'll want to read the documentation carefully if you intend to migrate.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'expo-server-sdk'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install expo-server-sdk

## Usage

```ruby
require 'expo-server-sdk'

# Create a new Expo SDK client optionally providing an access token if you
# have enabled push security
client = Expo::Push::Client.new(accessToken: '<access-token>');

# Create the messages that you want to send to clients
messages = [];

some_push_tokens.each do |push_token|
  # Each push token looks like ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]

  # Check that all your push tokens appear to be valid Expo push tokens.
  # If you don't do this, this library will raise an error when trying to
  # create the notification.
  #
  unless Expo::Push.expo_push_token?(push_token)
    puts "Push token #{pushToken} is not a valid Expo push token"
    next
  end

  # Construct a message (see https://docs.expo.io/push-notifications/sending-notifications/)
  #
  # Use client.notification, Expo::Push::Notification.new,
  # or Expo::Push::Notification.to, then follow it with one or more chainable
  # API calls, including, but not limited to:
  #
  # - #to: add recipient (or #add_recipient),
  #        add recipients (or #add_recipients)
  # - #title
  # - #subtitle
  # - #body (or #content)
  # - #data
  # - #priority
  # - #sound
  # - #channel_id
  # - #category_id
  #
  messages << client.notification
    .to(pushToken)
    .sound('default')
    .body('This is a test notification')
    .data({ withSome: 'data' })
end

# The Expo push notification service accepts batches of notifications so that
# you don't need to send 1000 requests to send 1000 notifications. We
# recommend you batch your notifications to reduce the number of requests and
# to compress them (notifications with similar content will get compressed).
#
# Using #send or #send! will automatically batch your messages.
#
# When using #send, the result is an array of tickets per batched chunk, or may
# be an error, such as a TicketsWithErrors error. It's up to you to inspect and
# handle those errors.
#
# When using #send!, all batches will first execute, and then the first error
# received is raised.
#
tickets = client.send!(messages)

# You can #explain(error) to attempt to explain nested errors. For example, say
# a batch contains failed errors, or completely failed pages:
#
tickets.each_error do |error|
  if error.is_a?(Error)
    puts error.message
    # => "This indicates the entire request had an error"
  else
    puts error.explain
    # => "The device cannot receive push notifications anymore and you should
    #     stop sending messages to the corresponding Expo push token."

    puts error.message
    # => ""ExpoPushToken[xxxxxxxxxxxxxxxxxxxxxx]" is not a registered push
    #     notification recipient"
    #
    # In the case of an DeviceNotRegistered, you can attempt to extract the
    # faulty push token:

    error.original_push_token
    # => ExpoPushToken[xxxxxxxxxxxxxxxxxxxxxx]
  end
end

# Later, after the Expo push notification service has delivered the
# notifications to Apple or Google (usually quickly, but allow the the service
# up to 30 minutes when under load), a "receipt" for each notification is
# created. The receipts will be available for at least a day; stale receipts
# are deleted.
#
# The ID of each receipt is sent back in the response "ticket" for each
# notification. In summary, sending a notification produces a ticket, which
# contains a receipt ID you later use to get the receipt.
#
# The receipts may contain error codes to which you must respond. In
# particular, Apple or Google may block apps that continue to send
# notifications to devices that have blocked notifications or have uninstalled
# your app. Expo does not control this policy and sends back the feedback from
# Apple and Google so you can handle it appropriately.
#
# Note: this will silently skip over any errors encountered. Use #each_error
#       to attempt to handle them yourself.
receipt_ids = tickets.ids

# You may want to be doing this in some job context, so this gem doesn't batch
# and call the endpoint manually, but you can generate the batches, and send
# then individually:
batches = tickets.batch_ids

# Now you can schedule your jobs, thread, or run this inline. All would work.
batches.each do |receipt_ids|
  # << schedule a job with this batch of ids >>
  # ...
  # inside the job or inline
  receipts = client.receipts(receipt_ids)

  # You can #explain(error) to attempt to explain receipts that have an
  # error status.
  #
  receipts.each_error do |receipt|
    puts error.explain
    # => "The device cannot receive push notifications anymore and you should
    #     stop sending messages to the corresponding Expo push token."

    puts error.message
    # => ""ExpoPushToken[xxxxxxxxxxxxxxxxxxxxxx]" is not a registered push
    #     notification recipient"
    #
    # In the case of an DeviceNotRegistered, you can attempt to extract the
    # faulty push token:

    error.original_push_token
    # => ExpoPushToken[xxxxxxxxxxxxxxxxxxxxxx]
  end

  # Because not all receipts may be returned, it is imported to schedule, or
  # retry the unresolved receipts at a later point in time:
  unresolved_ids = receipts.unresolved_ids

  # ...
  receipts = client.receipts(unresolved_ids) if unresolved_ids.length > 0
end
```

### Logging

It is very likely that you'll want to develop with logging turned on.
This can be accomplished by passing in a logger instance:

```ruby
require 'logger'

logger = Logger.new(STDOUT);
client = Expo::Push::Client.new(logger: logger)

# Now when doing requests like so:
client.send(notification)

# ...it will log
#
# I, [2021-10-25T02:16:11.284901 #16448]  INFO -- : > POST https://exp.host/--/api/v2/push/send
# D, [2021-10-25T02:16:11.285601 #16448] DEBUG -- : Accept: application/json
# Accept-Encoding: gzip
# User-Agent: expo-server-sdk-ruby/0.1.0
# Connection: Keep-Alive
# Content-Type: application/json; charset=UTF-8
# Host: exp.host
#
# [{"to":["ExpoPushToken[xxxxxxxxxxxxxxxxxxxxxx]"]}]
```

For more advanced logging, or instrumentation in general, use the Instrumentation feature.
It expects an `ActiveSupport::Notifications`-compatible instrumenter.

These are available in most Rails projects by default.

```ruby
ActiveSupport::Notifications.subscribe('start_request.http') do |name, start, finish, id, payload|
  pp :name => name, :start => start.to_f, :finish => finish.to_f, :id => id, :payload => payload
end

client = Expo::Push::Client.new(instrumentation: true)

# Now when doing requests like so:
client.send(notification)

# ...it will instrument
# => {name: .., start: .., finish: .., id: .., payload: ..}
```

You can configure the namespace (and instrumentation):

```ruby
client = Expo::Push::Client.new(
  instrumentation: {
    instrumenter: ActiveSupport::Notifications.instrumenter,
    namespace: "my_http"
  }
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SleeplessByte/expo-server-sdk-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/SleeplessByte/expo-server-sdk-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `Expo::Server::SDK` project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/SleeplessByte/expo-server-sdk/blob/master/CODE_OF_CONDUCT.md).

```

```

```

```
