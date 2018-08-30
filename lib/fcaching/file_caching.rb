require 'time'
require 'fileutils'

require_relative 'gen_caching'
require_relative 'refinements'

class FileCaching
  using Refinements

  include GenCaching

  DEFAULT_STORE_DIR = '.fcaching_store'

  attr_accessor :store_dir

  def initialize(store_dir = DEFAULT_STORE_DIR)
    filesystem_guard(store_dir)
    @store_dir = store_dir
  end

  def set(key, object, return_object: false)
    filesystem_guard(key)
    nil_value_guard(object)
    del(key)
    Dir.mkdir(store_dir) unless Dir.exist?(store_dir)
    File.write("#{store_dir}/#{key}_#{Time.now.iso8601(3)}", Marshal.dump(object))
    return_object ? object : true
  end

  def get(key, max_age: nil)
    filesystem_guard(key)
    existing_filenames(key, max_age: max_age).
      last&.
      then { |filename| "#{store_dir}/#{filename}" }&.
      then(&File.method(:binread))&.
      then(&Marshal.method(:load))
  end

  def del(key)
    filesystem_guard(key)
    existing_filenames(key).
      map { |filename| "#{store_dir}/#{filename}" }.
      then { |filepaths| File.delete(*filepaths) }
  end

  def clear_cache!
    FileUtils.rm_rf(store_dir) if Dir.exist?(store_dir)
  end

  def filesystem_guard(string)
    raise "'#{string}' is not UNIX filesystem friendly !" unless filesystem_friendly?(string)
  end

  def filesystem_friendly?(string)
    !string[/[^\w_\-\.]/]
  end

  private

  def existing_filenames(key, max_age: nil)
    return [] unless Dir.exist?(store_dir)
    Dir.children(store_dir).
      select do |filename|
        if (file_data = parse(filename))
          file_data[:base] == key and
            (
              max_age.nil? or
              file_data[:time] > (Time.now - max_age)
            )
        end
      end.
      sort
  end

  def parse(filename)
    filename.
      match(
        /
          (?<base>.*)
          _
          (?<time>[\d]{4}-[\d]{2}-[\d]{2}T[\d]{2}:[\d]{2}:[\d]{2}\.[\d]{3}\+[\d]{2}:[\d]{2})$
        /x)&.
      then do |match|
        {
          base: match[:base],
          time: Time.parse(match[:time])
        }
      end
  end
end
