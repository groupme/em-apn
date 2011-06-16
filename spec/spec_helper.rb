require "rubygems"
require "bundler/setup"
Bundler.require

RSpec.configure do |config|
  config.before(:each) do
    @logger = Logger.new("/dev/null")
    Logger.stub(:new).and_return(@logger)
  end
end
