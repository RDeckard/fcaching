require 'time'
require_relative 'refinements'

module FileCaching
  using Refinements

  extend self

  STORE_DIR = '.fcaching_store'
  Dir.mkdir(STORE_DIR) unless Dir.exist?(STORE_DIR)

  def fetch(key, max_age: nil, force: false, return_object: true)
    if block_given? and (force or not cached?(key, max_age: max_age))
      set(key, yield, return_object: return_object)
    else
      get(key, max_age: max_age)
    end
  end

  def set(key, object, return_object: false)
    filesystem_guard(key)
    del(key)
    File.write("#{STORE_DIR}/#{key}_#{Time.now.iso8601}", Marshal.dump(object))
    return_object ? object : true
  end

  def get(key, max_age: nil)
    filesystem_guard(key)
    existing_filenames(key, max_age: max_age).
      last&.
      then { |filename| "#{STORE_DIR}/#{filename}" }&.
      then(&File.method(:binread))&.
      then(&Marshal.method(:load))
  end

  def del(key)
    filesystem_guard(key)
    existing_filenames(key).
      map { |filename| "#{STORE_DIR}/#{filename}" }.
      then { |filepaths| File.delete(*filepaths) }
  end

  def cached?(key, max_age: nil)
    !existing_filenames(key, max_age: max_age).empty?
  end

  def filesystem_guard(string)
    raise "'#{string}' is not UNIX filesystem friendly !" unless filesystem_friendly?(string)
  end

  def filesystem_friendly?(string)
    !string[/[^\w_-]/]
  end

  private

  def existing_filenames(key, max_age: nil)
    Dir.children(STORE_DIR).
      select do |filename|
        file_data = parse(filename)
        file_data[:base] == key and
          (
            max_age.nil? or
            file_data[:time] > (Time.now - max_age)
          )
      end.
      sort_by { |filename| parse(filename)[:time] }
  end

  def parse(filename)
    filename.
      match(
        /
          (?<base>.*)
          _
          (?<time>[\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}\+[\d]{2}:[\d]{2})$
        /x).
      then do |match|
        {
          base: match[:base],
          time: Time.parse(match[:time])
        }
      end
  end
end
