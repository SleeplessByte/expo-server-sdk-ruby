# frozen_string_literal: true

module Expo
  module Push
    ##
    # A ticket represents a single receipt ticket.
    #
    # - In case of an #ok? ticket, holds the receipt id in #id
    # - In case of an #error? ticket, holds the #message, #explain
    #
    # Some failed tickets may expose which push token is not or no longer
    # valid. This is exposed via #original_push_token.
    #
    class Ticket
      attr_reader :data, :token

      def initialize(data, token)
        self.data = data
        self.token = token
      end

      def id
        data.fetch('id')
      end

      def original_push_token
        token
      end

      def message
        data.fetch('message')
      end

      def explain
        Expo::Push::Error.explain((data['details'] || {})['error'])
      end

      def ok?
        data['status'] == 'ok'
      end

      def error?
        data['status'] == 'error'
      end

      private

      attr_writer :data, :token
    end

    ##
    # Tickets are paged: each batch when sending the notifications is one
    # tickets entry. Each tickets entry has many tickets.
    #
    # To ease exploration and continuation of the tickets, use the
    # folowing methods:
    #
    # - #batch_ids: slices all the receipts into chunks
    # - #each: iterates over each single ticket that is NOT an error
    # - #each_error: iterates over each errorered batch and failed ticket
    #
    # You MUST handle each error, and you MUST first check if its an Error
    # or not, because of the way an entire batch call can fail.
    #
    # @see Ticket
    #
    class Tickets
      def initialize(results)
        self.results = results
      end

      def ids
        [].tap do |ids|
          each { |ticket| ids << ticket.id }
        end
      end

      def token_by_receipt_id
        tokens_by_receipt_id = {}
        tokens_by_receipt_id.tap do |hash|
          each { |ticket| hash[ticket.id] = ticket.original_push_token }
        end
      end

      def batch_ids
        ids.each_slice(PUSH_NOTIFICATION_RECEIPT_CHUNK_LIMIT).to_a
      end

      def each
        results.each do |tickets|
          next if tickets.is_a?(Error)

          tickets.each do |ticket|
            next unless ticket.ok?

            yield ticket
          end
        end
      end

      def each_error
        results.each do |tickets|
          if tickets.is_a?(Error)
            yield tickets
          else
            tickets.each do |ticket|
              next unless ticket.error?

              yield ticket
            end
          end
        end
      end

      private

      attr_accessor :results
    end
  end
end
