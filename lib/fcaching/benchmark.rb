require 'benchmark'

require_relative 'fcaching'

cache = FCaching.new

contexts = [
    {
      persistency: false,
      nb_of_trials: 10000,
      description: "persistency `off`"
    },
    {
      persistency: true,
      nb_of_trials: 100,
      description: "persistency `on`"
    }
  ]

average_ms = -> (total_s, nb_of_trials) do
  (total_s * 1000 / nb_of_trials).round(6)
end

value = 50.times.map{ ('a'..'z').to_a.sample }

contexts.each do |context|
  cache.default_persistency = context[:persistency]
  puts "#{context[:description]} (averages computed with #{context[:nb_of_trials]} trials):"

  2.times.map do
    cache.clear_cache!
    Benchmark.measure("initialize with #fetch:") do
      context[:nb_of_trials].times do |i|
        cache.fetch("key#{i}") { value }
      end
    end
  end.last.tap do |result|
    puts "  #{result.label}".ljust(50) +
      "#{average_ms.(result.total, context[:nb_of_trials])}".ljust(8, '0') + ' ms'
  end

  2.times.map do
    cache.clear_cache!
    Benchmark.measure("initialize with #fetch and the `force` option:") do
      context[:nb_of_trials].times do |i|
        cache.fetch("key#{i}", force: true) { value }
      end
    end
  end.last.tap do |result|
    puts "  #{result.label}".ljust(50) +
      "#{average_ms.(result.total, context[:nb_of_trials])}".ljust(8, '0') + ' ms'
  end

  2.times.map do
    cache.clear_cache!
    Benchmark.measure("initialize with #set:") do
      context[:nb_of_trials].times do |i|
        cache.set("key#{i}", value)
      end
    end
  end.last.tap do |result|
    puts "  #{result.label}".ljust(50) +
      "#{average_ms.(result.total, context[:nb_of_trials])}".ljust(8, '0') + ' ms'
  end

  2.times.map do
    cache.clear_cache!
    context[:nb_of_trials].times do |i|
      cache.set("key#{i}", value)
    end
    Benchmark.measure("update with #fetch:") do
      context[:nb_of_trials].times do |i|
        cache.fetch("key#{i}", force: true) { value }
      end
    end
  end.last.tap do |result|
    puts "  #{result.label}".ljust(50) +
      "#{average_ms.(result.total, context[:nb_of_trials])}".ljust(8, '0') + ' ms'
  end

  2.times.map do
    cache.clear_cache!
    context[:nb_of_trials].times do |i|
      cache.set("key#{i}", value)
    end
    Benchmark.measure("update with #set:") do
      context[:nb_of_trials].times do |i|
        cache.set("key#{i}", value)
      end
    end
  end.last.tap do |result|
    puts "  #{result.label}".ljust(50) +
      "#{average_ms.(result.total, context[:nb_of_trials])}".ljust(8, '0') + ' ms'
  end

  if context[:persistency]
    2.times.map do
      cache.clear_cache!
      context[:nb_of_trials].times do |i|
        cache.set("key#{i}", value)
      end
      cache.memcache.clear_cache!
      Benchmark.measure("get with #fetch with file recovery:") do
        context[:nb_of_trials].times do |i|
          cache.fetch("key#{i}")
        end
      end
    end.last.tap do |result|
      puts "  #{result.label}".ljust(50) +
        "#{average_ms.(result.total, context[:nb_of_trials])}".ljust(8, '0') + ' ms'
    end

    2.times.map do
      cache.clear_cache!
      context[:nb_of_trials].times do |i|
        cache.set("key#{i}", value)
      end
      cache.memcache.clear_cache!
      Benchmark.measure("get with #get with file recovery:") do
        context[:nb_of_trials].times do |i|
          cache.get("key#{i}")
        end
      end
    end.last.tap do |result|
      puts "  #{result.label}".ljust(50) +
        "#{average_ms.(result.total, context[:nb_of_trials])}".ljust(8, '0') + ' ms'
    end
  end

  2.times.map do
    cache.clear_cache!
    context[:nb_of_trials].times do |i|
      cache.set("key#{i}", value)
    end
    Benchmark.measure("get with #fetch:") do
      context[:nb_of_trials].times do |i|
        cache.fetch("key#{i}")
      end
    end
  end.last.tap do |result|
    puts "  #{result.label}".ljust(50) +
      "#{average_ms.(result.total, context[:nb_of_trials])}".ljust(8, '0') + ' ms'
  end

  2.times.map do
    cache.clear_cache!
    context[:nb_of_trials].times do |i|
      cache.set("key#{i}", value)
    end
    Benchmark.measure("get with #get:") do
      context[:nb_of_trials].times do |i|
        cache.get("key#{i}")
      end
    end
  end.last.tap do |result|
    puts "  #{result.label}".ljust(50) +
      "#{average_ms.(result.total, context[:nb_of_trials])}".ljust(8, '0') + ' ms'
  end
end

cache.clear_cache!
