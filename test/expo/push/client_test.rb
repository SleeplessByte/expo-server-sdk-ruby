# frozen_string_literal: true

require 'test_helper'

module Expo
  module Push
    class ClientTest < Minitest::Test
      def test_that_it_has_a_version_number
        refute_nil ::Expo::Push::Client::VERSION
      end

      # rubocop:disable Layout/LineLength
      def test_that_it_can_detect_an_expo_push_token
        assert Expo::Push.expo_push_token?('ExpoPushToken[xxxxxxxxxxxxxxxxxxxxxx]')
        assert Expo::Push.expo_push_token?('ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]')
        assert Expo::Push.expo_push_token?('F5741A13-BCDA-434B-A316-5DC0E6FFA94F')

        # FCM
        refute Expo::Push.expo_push_token?('dOKpuo4qbsM:APA91bHkSmF84ROx7Y-2eMGxc0lmpQeN33ZwDMG763dkjd8yjKK-rhPtiR1OoIWNG5ZshlL8oyxsTnQ5XtahyBNS9mJAvfeE6aHzv_mOF_Ve4vL2po4clMIYYV2-Iea_sZVJF7xFLXih4Y0y88JNYULxFfz-XXXXX')

        # APNs
        refute Expo::Push.expo_push_token?('5fa729c6e535eb568g18fdabd35785fc60f41c161d9d7cf4b0bbb0d92437fda0')
      end
      # rubocop:enable Layout/LineLength
    end
  end
end
