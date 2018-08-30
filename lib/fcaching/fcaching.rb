require_relative 'mem_caching'
require_relative 'file_caching'

class FCaching

  attr_accessor :default_persistency, :memcache, :filecache

  def initialize(store_dir: nil, default_persistency: true)
    @default_persistency = default_persistency
    @memcache  = MemCaching.new
    @filecache = FileCaching.new(store_dir || FileCaching::DEFAULT_STORE_DIR)
  end

  def fetch(key, max_age: nil, force: false, return_object: true, persistency: default_persistency)
    if block_given?
      if force
        set(key, yield, return_object: return_object, persistency: persistency)
      elsif (retrieved_mem_value = memcache.get(key, max_age: max_age)).nil?
        if !persistency or (retrieved_file_value = filecache.get(key, max_age: max_age)).nil?
          set(key, yield, return_object: return_object, persistency: persistency)
        else
          persistency && filecache.filesystem_guard(key)
          memcache.set(key,
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
    persistency && filecache.filesystem_guard(key)
    memcache.set(key, object) &&
      persistency && filecache.set(key, object)
    return_object ? object : true
  end

  def get(key, max_age: nil, persistency: default_persistency)
    if (retrieved_mem_value = memcache.get(key, max_age: max_age)).nil?
      if persistency
        filecache.filesystem_guard(key)
        unless (retrieved_file_value = filecache.get(key, max_age: max_age)).nil?
          memcache.set(key,
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
    persistency && filecache.filesystem_guard(key)
    if (res = memcache.del(key) + (persistency ? filecache.del(key) : 0)) % (persistency ? 2 : 1) == 0
      res / (persistency ? 2 : 1)
    else
      (res / (persistency ? 2.0 : 1.0)).round(1)
    end
  end

  def clear_cache!
    memcache.clear_cache!
    filecache.clear_cache!
  end
end
