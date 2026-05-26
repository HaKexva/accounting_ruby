# frozen_string_literal: true

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  SCREEN = [ 1400, 900 ].freeze

  CI_CHROME_ARGS = [
    "--headless=new",
    "--no-sandbox",
    "--disable-dev-shm-usage",
    "--disable-gpu",
    "--window-size=1400,900"
  ].freeze

  if ENV["CI"].present?
    Capybara.register_driver :ci_chrome do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      CI_CHROME_ARGS.each { |arg| options.add_argument(arg) }
      options.binary = ENV.fetch("CHROME_BIN", "/usr/bin/chromium")

      service = Selenium::WebDriver::Chrome::Service.new(
        path: ENV.fetch("CHROMEDRIVER_PATH", "/usr/bin/chromedriver")
      )

      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, service: service)
    end

    driven_by :ci_chrome, screen_size: SCREEN
  else
    driven_by :selenium, using: :headless_chrome, screen_size: SCREEN
  end
end
