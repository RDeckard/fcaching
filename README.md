# FCaching

Easy caching (in memory + files persistency) for Ruby objects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fcaching', github: 'RDeckard/fcaching'
```

And then execute:

    $ bundle

## Usage

### `FCaching.fetch` - the Swiss Army knife of caching

Basic usage - store and fetch:

```ruby
FCaching.fetch("key1")
# => nil       # Nothing is stored yet for this key
FCaching.fetch("key1") { "value" }
# => "value"   # The block is evaluated, its result is cached and returned
FCaching.fetch("key1")
# => "value"   # The cached value is returned (even after
               # restarting the script or application)
```

Fetch and update basic policy:

```ruby
FCaching.fetch("key2") { {a: 1, b: 2} } # Store a new key/value
# => {:a=>1, :b=>2}
FCaching.fetch("key2") { {a: 2, b: 4} }
# => {:a=>1, :b=>2}   # The block is not evaluated because
                      # of the existance of the cached value
FCaching.fetch("key2", force: true) { {a: 2, b: 4} }
# => {:a=>2, :b=>4}   # The cache is updated by force with
                      # the returned value of the block
```

Fetch and update policy based on time:

```ruby
FCaching.fetch("key3") { {a: 1, "b" => :value} } # Store a new key/value
# => {:a=>1, "b"=>:value}

sleep 2
FCaching.fetch("key3", max_age: 1)
# => nil                          # The cache is not fetched because of its age
ruby_object = Object.new
# => #<Object:0x000056111cfb3d98>
FCaching.fetch("key3", max_age: 3) { ruby_object }
# => {:a=>1, "b"=>:value}         # The cached value is young enough so it
                                  # is fetched, and the block is not evaluated
sleep 2
FCaching.fetch("key3", max_age: 3) { ruby_object }
# => #<Object:0x000056111cfb3d98> # The cache is updated by the block
                                  # because of its outdated age (sorry dude)
```

### Other "Low level" methods

`FCaching.set` (basic (over)writings in cache):

```ruby
FCaching.set("key1", "nothing is")
# => true
FCaching.get("key1")
# => "nothing is"
FCaching.set("key1", "something")
# => true
FCaching.get("key1")
# => "something"
```

`FCaching.get` (basic readings in cache):

```ruby
FCaching.get("key4")
# => nil
FCaching.set("key4", "something")
# => true
FCaching.get("key4")
# => "something"
sleep 2
FCaching.get("key4", max_age: 1)
# => nil
FCaching.get("key4", max_age: 3)
# => "something"
```

`FCaching.delete`:

```ruby
FCaching.del("key5")
# => 0
FCaching.set("key1", "something")
# => true
FCaching.get("key1")
# => "something"
FCaching.del("key1")
# => 1
FCaching.del("key1")
# => 0
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/fcaching. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the FCaching project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/fcaching/blob/master/CODE_OF_CONDUCT.md).
