require 'bundler/setup'
Bundler.setup

ENV['RAILS_ENV'] ||= 'test'
ENV['RAILS_ROOT'] = File.expand_path('../dummy',  __FILE__)
require File.expand_path('../dummy/config/environment', __FILE__)

require 'pry'

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

Rspec.configure do |config|
  config.include Responses
end
