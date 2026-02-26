# frozen_string_literal: true

require "onvo"
require "webmock/rspec"

Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.order = :random
  Kernel.srand config.seed

  config.before do
    Onvo.reset!
    Onvo.secret_key = OnvoHelpers::TEST_SECRET_KEY
  end

  WebMock.disable_net_connect!
end
