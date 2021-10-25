# frozen_string_literal: true

module Expo
  module Push
    ##
    # Data model for PushNotification.
    #
    class Notification # rubocop:disable Metrics/ClassLength
      attr_accessor :recipients

      def self.to(recipient)
        new.to(recipient)
      end

      def initialize(_recipient = [])
        self.recipients = []
        self._params = {}
      end

      ##
      # Set or add recipient or recipients.
      #
      # Must be a valid Expo Push Token, or array-like / enumerator that yield
      # valid Expo Push Tokens, or an PushTokenInvalid error is raised.
      #
      # @see PushTokenInvalid
      # @see #<<
      #
      def to(recipient_or_multiple)
        Array(recipient_or_multiple).each do |recipient|
          self << recipient
        end

        self
      rescue NoMethodError
        raise ArgumentError, 'to must be a single Expo Push Token, or an array-like/enumerator of Expo Push Tokens'
      end

      ##
      # Set or overwrite the data.
      #
      # Data must be a Hash, or at least be JSON serializable as hash.
      #
      # A JSON object delivered to your app. It may be up to about 4KiB; the
      # total notification payload sent to Apple and Google must be at most
      # 4KiB or else you will get a "Message Too Big" error.
      #
      def data(value)
        json_data = value.respond_to?(:as_json) ? value.as_json : value.to_h

        raise ArgumentError, 'data must be hash-like or nil' if !json_data.nil? && !json_data.is_a?(Hash)

        _params[:data] = json_data
        self
      rescue NoMethodError
        raise ArgumentError, 'data must be hash-like, respond to as_json, or nil'
      end

      ##
      # Set or overwrite the title.
      #
      # The title to display in the notification. Often displayed above the
      # notification body.
      #
      def title(value)
        _params[:title] = value.nil? ? nil : String(value)
        self
      rescue NoMethodError
        raise ArgumentError, 'title must be nil or string-like'
      end

      ##
      # Set or overwrite the subtitle.
      #
      # The subtitle to display in the notification below the title.
      #
      # @note iOS only
      #
      def subtitle(value)
        _params[:subtitle] = value.nil? ? nil : String(value)
        self
      rescue NoMethodError
        raise ArgumentError, 'subtitle must be nil or string-like'
      end

      alias sub_title subtitle

      ##
      # Set or overwrite the body (content).
      #
      # The message to display in the notification.
      #
      def body(value)
        _params[:body] = value.nil? ? nil : String(value)
        self
      rescue NoMethodError
        raise ArgumentError, 'body must be nil or string-like'
      end

      alias content body

      ##
      # Set or overwrite the sound.
      #
      # Play a sound when the recipient receives this notification. Specify
      # "default" to play the device's default notification sound, or nil to
      # play no sound. Custom sounds are not supported.
      #
      # @note iOS only
      #
      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def sound(value)
        if value.nil?
          _params[:sound] = nil
          return self
        end

        unless value.respond_to?(:to_h)
          _params[:sound] = String(value)
          return self
        end

        json_value = value.to_h

        next_value = {
          critical: !json_value.fetch(:critical, nil).nil?,
          name: json_value.fetch(:name, nil),
          volume: json_value.fetch(:volume, nil)
        }

        next_value[:name] = String(next_value[:name]) unless next_value[:name].nil?
        next_value[:volume] = next_value[:volume].to_i unless next_value[:volume].nil?

        _params[:sound] = next_value.compact

        self
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      ##
      # Set or overwrite the time to live in seconds.
      #
      # The number of seconds for which the message may be kept around for
      # redelivery if it hasn't been delivered yet. Defaults to nil in order to
      # use the respective defaults of each provider:
      #
      # - 0 for iOS/APNs
      # - 2419200 (4 weeks) for Android/FCM
      #
      # @see expiration
      #
      # @note On Android, we make a best effort to deliver messages with zero
      #   TTL immediately and do not throttle them. However, setting TTL to a
      #   low value (e.g. zero) can prevent normal-priority notifications from
      #   ever reaching Android devices that are in doze mode. In order to
      #   guarantee that a notification will be delivered, TTL must be long
      #   enough for the device to wake from doze mode.
      #
      def ttl(value)
        _params[:ttl] = value.nil? ? nil : value.to_i
        self
      rescue NoMethodError
        raise ArgumentError, 'ttl must be numeric or nil'
      end

      ##
      # Set or overwrite the time to live based on a unix timestamp.
      #
      # Timestamp since the UNIX epoch specifying when the message expires.
      # Same effect as ttl (ttl takes precedence over expiration).
      #
      # @see ttl
      #
      def expiration(value)
        _params[:expiration] = value.nil? ? nil : value.to_i
        self
      rescue NoMethodError
        raise ArgumentError, 'ttl must be numeric or nil'
      end

      ##
      # Set or overwrite the priority.
      #
      # The delivery priority of the message. Specify "default" or nil to use
      # the default priority on each platform:
      #
      # - "normal" on Android
      # - "high" on iOS
      #
      # @note On Android, normal-priority messages won't open network
      #   connections on sleeping devices and their delivery may be delayed to
      #   conserve the battery. High-priority messages are delivered
      #   immediately if possible and may wake sleeping devices to open network
      #   connections, consuming energy.
      #
      # @note On iOS, normal-priority messages are sent at a time that takes
      #   into account power considerations for the device, and may be grouped
      #   and delivered in bursts. They are throttled and may not be delivered
      #   by Apple. High-priority messages are sent immediately.
      #   Normal priority corresponds to APNs priority level 5 and high
      #   priority to 10.
      #
      # rubocop:disable Metrics/MethodLength
      def priority(value)
        if value.nil?
          _params[:priority] = nil
          return self
        end

        priority_string = String(value)

        unless %w[default normal high].include?(priority_string)
          raise ArgumentError, 'priority must be default, normal, or high'
        end

        _params[:priority] = priority_string
        self
      rescue NoMethodError
        raise ArgumentError, 'priority must be default, normal, or high'
      end
      # rubocop:enable Metrics/MethodLength

      ##
      # Set or overwrite the new badge count.
      #
      # Use 0 to clear, use nil to keep as is.
      #
      # @note iOS only
      #
      def badge(value)
        _params[:badge] = value.nil? ? nil : value.to_i
        self
      rescue NoMethodError
        raise ArgumentError, 'badge must be numeric or nil'
      end

      ##
      # Set or overwrite the channel ID.
      #
      # ID of the Notification Channel through which to display this
      # notification. If an ID is specified but the corresponding channel does
      # not exist on the device (i.e. has not yet been created by your app),
      # the notification will not be displayed to the user.
      #
      # @note If left nil, a "Default" channel will be used, and Expo will
      #   create the channel on the device if it does not yet exist. However,
      #   use caution, as the "Default" channel is user-facing and you may not
      #   be able to fully delete it.
      #
      # @note Android only
      #
      def channel_id(value)
        _params[:channelId] = value.nil? ? nil : String(value)
        self
      rescue NoMethodError
        raise ArgumentError, 'channelId must be string-like or nil to use "Default"'
      end

      alias channel_identifier channel_id

      ##
      # Set or overwrite the category ID
      #
      # ID of the notification category that this notification is associated
      # with. Must be on at least SDK 41 or bare workflow.
      #
      # Notification categories allow you to create interactive push
      # notifications, so that a user can respond directly to the incoming
      # notification either via buttons or a text response. A category defines
      # the set of actions a user can take, and then those actions are applied
      # to a notification by specifying the categoryId here.
      #
      # @see https://docs.expo.dev/versions/latest/sdk/notifications/#managing-notification-categories-interactive-notifications
      #
      def category_id(value)
        _params[:categoryId] = value.nil? ? nil : String(value)
        self
      rescue NoMethodError
        raise ArgumentError, 'categoryId must be string-like or nil'
      end

      ##
      # Set or overwrite the mutability flag.
      #
      # Use nil to use the defaults.
      #
      # Specifies whether this notification can be intercepted by the client
      # app. In Expo Go, this defaults to true, and if you change that to
      # false, you may experience issues. In standalone and bare apps, this
      # defaults to false.
      #
      def mutable_content(value)
        _params[:mutableContent] = value.nil? ? nil : !value.nil?
        self
      end

      alias mutable mutable_content

      ##
      # Add a single recipient
      #
      # Must be a valid Expo Push Token, or a PushTokenInvalid error is raised.
      #
      # @see PushTokenInvalid
      # @see #to
      #
      def <<(recipient)
        raise PushTokenInvalid.new(token: recipient) unless Expo::Push.expo_push_token?(recipient)

        recipients << recipient

        self
      end

      alias add_recipient <<
      alias add_recipients to

      ##
      # Allows overwriting the recipients list which is necessary to prepare
      # the notification when chunking.
      #
      def prepare(targets)
        dup.tap do |prepared|
          prepared.reset_recipients(targets)
        end
      end

      def count
        recipients.length
      end

      def as_json
        puts _params

        { to: recipients }.merge(_params.compact)
      end

      def reset_recipients(targets)
        self.recipients = []
        add_recipients(targets)
      end

      private

      attr_accessor :_params
    end
  end
end
