# frozen_string_literal: true

require 'test_helper'

module Expo
  module Server
    class SdkTest < Minitest::Test
      def test_that_it_has_a_version_number
        refute_nil ::Expo::Server::SDK::VERSION
      end
    end
  end
end
