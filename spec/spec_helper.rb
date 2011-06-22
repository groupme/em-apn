require "rubygems"
require "bundler/setup"
Bundler.require :default, :development

require "em-apn/test_helper"

RSpec.configure do |config|
  config.before(:each) do
    ENV["APN_KEY"]  = "spec/support/certs/key.pem"
    ENV["APN_CERT"] = "spec/support/certs/cert.pem"

    EM::APN.logger = Logger.new("/dev/null")
  end
end
