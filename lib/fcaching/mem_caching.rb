module MemCaching
  extend self

  @mem_store = Hash.new { {} }

  class << self
    def included(mod)
      mod.instance_variable_set :@mem_store, Hash.new { {} }
    end
    alias_method :extended, :included
  end

  def fetch(key, max_age: nil, force: false, return_object: true)
    if block_given? and (force or not cached?(key, max_age: max_age))
      set(key, yield, return_object: return_object)
    else
      get(key, max_age: max_age)
    end
  end

  def set(key, object, return_object: false)
    del(key)
    @mem_store[key] = @mem_store[key].merge({Time.now => object}).sort.to_h
    return_object ? object : true
  end

  def get(key, max_age: nil)
    existing_timed_values(key, max_age: max_age).values.last
  end

  def del(key)
    @mem_store.delete(key)&.keys&.count.to_i
  end

  def cached?(key, max_age: nil)
    !existing_timed_values(key, max_age: max_age).empty?
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
end
