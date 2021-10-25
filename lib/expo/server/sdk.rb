# frozen_string_literal: true

require_relative 'sdk/version'
require_relative '../../push/client'

module Expo
  module Server
    module SDK # rubocop:disable Style/Documentation
      def self.push
        Expo::Push::Client
      end
    end
  end
end
