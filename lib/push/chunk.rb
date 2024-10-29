# frozen_string_literal: true

module Expo
  module Push
    class Chunk # rubocop:disable Style/Documentation
      def self.for(notifications) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        Array(notifications).each_with_object([]) do |notification, chunks|
          # There can be at most n notifications in a chunk. This finds the last chunk,
          # checks how much space is left, and generates a new chunk if necessary.
          chunk = chunks.last || Chunk.new.tap { |c| chunks << c }

          targets = notification.recipients.dup

          while targets.length.positive?
            chunk = Chunk.new.tap { |c| chunks << c } if chunk.remaining <= 0

            # Take at most <remaining> destinations for this notificiation.
            count = [targets.length, chunk.remaining].min
            chunk_targets = targets.slice(0, count)

            # Prepare the notification
            chunk << notification.prepare(chunk_targets)

            # Remove targets from the targets list
            targets = targets.drop(count)
          end
        end
      end

      attr_reader :remaining

      def initialize
        self.notifications = []
        self.remaining = PUSH_NOTIFICATION_CHUNK_LIMIT
      end

      def <<(notification)
        self.remaining -= notification.count
        notifications << notification

        self
      end

      def count
        notifications.sum(&:count)
      end

      def as_json
        notifications.map(&:as_json)
      end

      def all_recipients
        notifications.flat_map(&:recipients)
      end

      private

      attr_accessor :notifications
      attr_writer :remaining
    end
  end
end
