require_relative 'gen_caching'
require_relative 'refinements'

class MemCaching
  using Refinements

  include GenCaching

  def initialize
    @mem_store = Hash.new { {} }
  end

  def set(key, object, return_object: false)
    nil_value_guard(object)
    del(key)
    @mem_store[key] = @mem_store[key].merge(
        {Time.now => deep_copy(object)}
      ).sort.to_h
    return_object ? object : true
  end

  def get(key, max_age: nil)
    existing_timed_values(key, max_age: max_age).values.last
  end

  def del(key)
    @mem_store.delete(key)&.keys&.count.to_i
  end

  def clear_cache!
    @mem_store = Hash.new { {} }
  end

  private

  def existing_timed_values(key, max_age: nil)
    @mem_store[key].
      select do |time, object|
          (
            max_age.nil? or
            time > (Time.now - max_age)
          )
      end
  end

  def deep_copy(object)
    object.
      then(&Marshal.method(:dump)).
      then(&Marshal.method(:load))
  end
end
