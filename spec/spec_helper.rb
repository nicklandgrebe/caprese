require 'bundler/setup'
Bundler.setup

require 'coveralls'
Coveralls.wear!

ENV['RAILS_ENV'] ||= 'test'
ENV['RAILS_ROOT'] = File.expand_path('../dummy',  __FILE__)
require File.expand_path('../dummy/config/environment', __FILE__)

require 'database_cleaner'
require 'factory_girl'
require 'pry'
require 'rspec/rails'

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include Responses

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
