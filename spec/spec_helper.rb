require "rubygems"
require "bundler/setup"
Bundler.require :default, :development

RSpec.configure do |config|
  config.before(:each) do
    ENV["APN_KEY"]     = "spec/support/certs/key.pem"
    ENV["APN_CERT"]    = "spec/support/certs/cert.pem"
    ENV["APN_GATEWAY"] = "127.0.0.1"

    EM::APN.logger = Logger.new("/dev/null")
  end
end
