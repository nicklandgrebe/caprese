# Caprese

Caprese is a Rails library for creating RESTful APIs in as few words as possible. It handles all CRUD operations on resources and their associations for you, and you can customize how these operations
are carried out by overriding intermediate helper methods and by defining callbacks around any CRUD action.

What separates Caprese from similar gems is that it is trying to do as little as possible, instead allowing gems that are better at other things to do what they are good at, as opposed to Caprese trying to do it all.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'caprese'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install caprese

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nicklandgrebe/caprese.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
