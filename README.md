# DomoRubySdk

This is a Ruby based interface that invokes the Domo REST Data API on behalf of the application.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "domo_ruby_sdk", git: "https://github.com/visual4site/domo_ruby_sdk"
```
Once this is deployed to a Gem repository, then the github repo url will not be necessary.

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install domo_ruby_sdk

## Usage

Please review the ./spec/domo_ruby_sdk_spec.rb for usage examples. Here you can:

* authenticate with domo
* create a dataset
* delete a dataset
* fetch list of datasets
* create dataset stream
* publish to dataset stream
* finalize dataset stream



## Development

The rspec tests are full integration tests that try to connect to a domo instance. In order to run the rspec tests, you must set the following two environment variables for the Domo credentials:

V4SITE_TEST_DOMO_CLIENT_ID
V4SITE_TEST_DOMO_CLIENT_SECRET


To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/visual4site/domo_ruby_sdk.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
