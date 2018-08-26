require_relative "fcaching/version"
require_relative "fcaching/file_caching"
require_relative "fcaching/mem_caching"

module FCaching
  extend self

  def fetch(key, max_age: nil, force: false, return_object: true)
    if block_given? and
        (
          force or
            not (
              MemCaching.cached?(key, max_age: max_age) or
              FileCaching.cached?(key, max_age: max_age)
            )
        )
      set(key, yield, return_object: return_object)
    else
      get(key, max_age: max_age)
    end
  end

  def set(key, object, return_object: false)
    MemCaching.set(key, object) &&
      FileCaching.set(key, object)
    return_object ? object : true
  end

  def get(key, max_age: nil)
    MemCaching.get(key, max_age: max_age) ||
      (file_cached_value = FileCaching.get(key, max_age: max_age)) &&
      MemCaching.set(key,
          file_cached_value,
          return_object: true
        )
  end

  def del(key)
    if (res = MemCaching.del(key) + FileCaching.del(key)) % 2 == 0
      res / 2
    else
      (res / 2.0).round(1)
    end
  end
end
