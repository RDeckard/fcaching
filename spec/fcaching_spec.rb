module ExtendedMemModule
  extend MemCaching
end

module ExtendedFileModule
  extend FileCaching
end

[MemCaching, ExtendedMemModule, FileCaching, ExtendedFileModule, FCaching].each do |mod|
  RSpec.describe mod do
    before(:each) do
      mod.del('key')
    end

    contexts =
      case mod
      when FCaching
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
        mod.default_persistency = context unless context.nil?
        describe %i[set get].join(',') do
          it "should do basic caching actions" do
            first_value = 'nothing is'

            expect(mod.get('key')).
              to eq nil

            expect(mod.set('key', first_value)).
              to eq true

            expect(mod.get('key')).
              to eq first_value

            new_value = 'something'

            expect(mod.set('key', new_value)).
              to eq true

            expect(mod.get('key')).
              to eq new_value
          end

          it "should handle time policies" do
            tested_value = 'something'
            mod.set('key', tested_value)

            sleep 2

            expect(mod.get('key', max_age: 1)).
              to eq nil

            expect(mod.get('key', max_age: 3)).
              to eq tested_value
          end
        end

        describe :del do
          it "should delete cached value and return the number of deleted values" do
            mod.del('new_key')
            mod.set('key', 'something')

            expect(mod.del('new_key')).
              to eq 0

            expect(mod.del('key')).
              to eq 1

            expect(mod.del('key')).
              to eq 0
          end
        end

        describe :fetch do
          it "should store and fetch values" do
            expect(mod.fetch('key')).
              to eq nil

            value = 'value'

            expect(mod.fetch('key') { value }).
              to eq value

            expect(mod.fetch('key')).
              to eq value
          end

          it "should can update value by force" do
            first_value = {a: 1, b: 2}

            expect(mod.fetch('key') { first_value }).
              to eq first_value

            new_value = {a: 2, b: 4}

            expect(mod.fetch('key') { new_value }).
              to eq first_value

            expect(mod.fetch('key', force: true) { new_value }).
              to eq new_value
          end

          it "should can update value based on time policies" do
            first_value = {a: 1, b: 2}

            expect(mod.fetch('key') { first_value }).
              to eq first_value

            sleep 2

            expect(mod.fetch('key', max_age: 1)).
              to eq nil

            ruby_object = Object.new

            expect(mod.fetch('key', max_age: 3) { ruby_object }).
              to eq first_value

            sleep 2

            expect(mod.fetch('key', max_age: 3) { ruby_object }).
              to eq ruby_object
          end
        end
      end
    end
  end
end

RSpec.describe FCaching do
  it "has a version number" do
    expect(FCaching::VERSION).not_to be nil
  end

  context 'default persistency set on `true`' do
    FCaching.default_persistency = true

    it "should use 'file caching' when 'mem caching' can't retrieve cached value" do
      value = 'value'
      FCaching.del('key')
      FCaching.fetch('key') { value }

      expect(FCaching.fetch('key')).
        to eq value
      expect(FCaching.get('key')).
        to eq value

      expect(MemCaching.fetch('key')).
        to eq value
      expect(MemCaching.get('key')).
        to eq value

      MemCaching.clear_cache!

      expect(MemCaching.fetch('key')).
        to eq nil
      expect(MemCaching.get('key')).
        to eq nil

      expect(FCaching.fetch('key')).
        to eq value
      expect(FCaching.get('key')).
        to eq value
    end

    it "should have update 'mem caching' with this 'file cached' value" do
      value = 'value'

      expect(MemCaching.fetch('key')).
        to eq value
      expect(MemCaching.get('key')).
        to eq value
    end
  end
end
