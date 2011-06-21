require "rubygems"
require "bundler/setup"
Bundler.require

RSpec.configure do |config|
  config.before(:each) do
    ENV["APN_KEY"]  = "spec/support/certs/key.pem"
    ENV["APN_CERT"] = "spec/support/certs/cert.pem"

    EM::APN.logger = Logger.new("/dev/null")
  end
end
