SLEEP_TIMESTEP=0.1

[MemCaching, FileCaching, FCaching].each do |klass|
  RSpec.describe "#{klass} instance" do
    before(:example) do
      @cache = klass.new
      @cache.del('key')
    end

    after(:example) do
      @cache.clear_cache!
      @cache = nil
    end

    contexts =
      if klass == FCaching
        {
          true => 'default persistency set on `true`',
          false => 'default persistency set on `false`'
        }
      else
        {
          nil => 'normal'
        }
      end

    contexts.each do |context, description|
      context description do
        describe %i[set get].join(',') do
          it "should do basic caching actions" do
            @cache.default_persistency = context unless context.nil?

            first_value = 'nothing'

            expect(@cache.get('key')).
              to eq nil

            expect(@cache.set('key', first_value)).
              to eq true

            expect(@cache.get('key')).
              to eq first_value

            new_value = 'something'

            expect(@cache.set('key', new_value)).
              to eq true

            expect(@cache.get('key')).
              to eq new_value
          end

          it "should handle time policies" do
            @cache.default_persistency = context unless context.nil?

            expect(@cache.get('key')).
              to eq nil

            tested_value = 'something'

            @cache.set('key', tested_value)

            sleep(2 * SLEEP_TIMESTEP)

            expect(@cache.get('key', max_age: SLEEP_TIMESTEP)).
              to eq nil

            expect(@cache.get('key', max_age: (3 * SLEEP_TIMESTEP))).
              to eq tested_value
          end
        end

        describe :del do
          it "should delete cached value and return the number of deleted values" do
            @cache.default_persistency = context unless context.nil?

            expect(@cache.get('key')).
              to eq nil

            @cache.set('key', 'something')

            expect(@cache.del('new_key')).
              to eq 0

            expect(@cache.del('key')).
              to eq 1

            expect(@cache.del('key')).
              to eq 0
          end
        end

        describe :fetch do
          it "should store and fetch values" do
            @cache.default_persistency = context unless context.nil?

            expect(@cache.fetch('key')).
              to eq nil

            value = 'value'

            expect(@cache.fetch('key') { value }).
              to eq value

            expect(@cache.fetch('key')).
              to eq value
          end

          it "should can update value by force" do
            @cache.default_persistency = context unless context.nil?

            expect(@cache.get('key')).
              to eq nil

            first_value = {a: 1, b: 2}

            expect(@cache.fetch('key') { first_value }).
              to eq first_value

            new_value = {a: 2, b: 4}

            expect(@cache.fetch('key') { new_value }).
              to eq first_value

            expect(@cache.fetch('key', force: true) { new_value }).
              to eq new_value
          end

          it "should can update value based on time policies" do
            @cache.default_persistency = context unless context.nil?

            expect(@cache.get('key')).
              to eq nil

            first_value = {a: 1, b: 2}

            expect(@cache.fetch('key') { first_value }).
              to eq first_value

            sleep(2 * SLEEP_TIMESTEP)

            expect(@cache.fetch('key', max_age: SLEEP_TIMESTEP)).
              to eq nil

            ruby_object = Object.new

            expect(@cache.fetch('key', max_age: (3 * SLEEP_TIMESTEP)) { ruby_object }).
              to eq first_value

            sleep(2 * SLEEP_TIMESTEP)

            expect(@cache.fetch('key', max_age: (3 * SLEEP_TIMESTEP)) { ruby_object }).
              to eq ruby_object
          end
        end
      end
    end
  end
end

RSpec.describe FCaching do
    before(:context) do
      @cache = FCaching.new(default_persistency: true)
      @cache.del('key')
      @value = 'value'
    end

    after(:context) do
      @cache.clear_cache!
      @cache = nil
    end
  it "has a version number" do
    expect(FCaching::VERSION).not_to be nil
  end

  context 'default persistency set on `true`' do
    it "should use 'file caching' when 'mem caching' can't retrieve a cached value" do
      expect(@cache.get('key')).
        to eq nil

      @cache.set('key', @value)

      expect(@cache.fetch('key')).
        to eq @value
      expect(@cache.get('key')).
        to eq @value

      expect(@cache.memcache.fetch('key')).
        to eq @value
      expect(@cache.memcache.get('key')).
        to eq @value

      @cache.memcache.clear_cache!

      expect(@cache.memcache.fetch('key')).
        to eq nil
      expect(@cache.memcache.get('key')).
        to eq nil

      expect(@cache.fetch('key')).
        to eq @value
      expect(@cache.get('key')).
        to eq @value
    end

    it "should then have updated 'mem caching' with the 'file cached' value" do
      expect(@cache.memcache.fetch('key')).
        to eq @value
      expect(@cache.memcache.get('key')).
        to eq @value
    end
  end
end
