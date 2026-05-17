# frozen_string_literal: true

require "test_helper"

class LocalHostAccessTest < ActiveSupport::TestCase
  test "localhost_host detects local browser hosts" do
    %w[localhost 127.0.0.1 ::1 [::1]].each do |host|
      assert LocalHostAccess.localhost_host?(host), "expected #{host} to count as localhost"
    end
  end

  test "localhost_host ignores production hosts" do
    assert_not LocalHostAccess.localhost_host?("myapp.up.railway.app")
  end
end
