module GenCaching
  def fetch(key, max_age: nil, force: false, return_object: true)
    if block_given?
      if force or (retrieved_value = get(key, max_age: max_age)).nil?
        set(key, yield, return_object: return_object)
      else
        retrieved_value
      end
    else
      get(key, max_age: max_age)
    end
  end

  def nil_value_guard(object)
    raise "Can't store `nil` value right now !" if object.nil?
  end
end
