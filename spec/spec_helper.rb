require 'bundler/setup'
Bundler.setup

ENV['RAILS_ENV'] ||= 'test'
ENV['RAILS_ROOT'] = File.expand_path('../dummy',  __FILE__)
require File.expand_path('../dummy/config/environment', __FILE__)

require 'factory_girl'
require 'pry'
require 'rspec/rails'

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include Responses
end
