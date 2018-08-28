require_relative 'mem_caching'
require_relative 'file_caching'

module FCaching
  extend self

  @default_persistency = true

  class << self
    attr_accessor :default_persistency
  end

  def fetch(key, max_age: nil, force: false, return_object: true, persistency: default_persistency)
    if block_given?
      if force
        set(key, yield, return_object: return_object, persistency: persistency)
      elsif (retrieved_mem_value = MemCaching.get(key, max_age: max_age)).nil?
        if !persistency or (retrieved_file_value = FileCaching.get(key, max_age: max_age)).nil?
          set(key, yield, return_object: return_object, persistency: persistency)
        else
          persistency && FileCaching.filesystem_guard(key)
          MemCaching.set(key,
              retrieved_file_value,
              return_object: true
            )
        end
      else
        retrieved_mem_value
      end
    else
      get(key, max_age: max_age, persistency: persistency)
    end
  end

  def set(key, object, return_object: false, persistency: default_persistency)
    persistency && FileCaching.filesystem_guard(key)
    MemCaching.set(key, object) &&
      persistency && FileCaching.set(key, object)
    return_object ? object : true
  end

  def get(key, max_age: nil, persistency: default_persistency)
    if (retrieved_mem_value = MemCaching.get(key, max_age: max_age)).nil?
      if persistency
        FileCaching.filesystem_guard(key)
        unless (retrieved_file_value = FileCaching.get(key, max_age: max_age)).nil?
          MemCaching.set(key,
              retrieved_file_value,
              return_object: true
            )
        end
      end
    else
      retrieved_mem_value
    end
  end

  def del(key, persistency: default_persistency)
    persistency && FileCaching.filesystem_guard(key)
    if (res = MemCaching.del(key) + (persistency ? FileCaching.del(key) : 0)) % (persistency ? 2 : 1) == 0
      res / (persistency ? 2 : 1)
    else
      (res / (persistency ? 2.0 : 1.0)).round(1)
    end
  end

  def clear_cache!
    MemCaching.clear_cache!
    FileCaching.clear_cache!
  end
end
