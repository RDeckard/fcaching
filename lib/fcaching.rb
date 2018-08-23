# require "fcaching/version"

require 'time'

module Refinements
  refine Kernel do
    alias_method :then, :yield_self
  end
end

module FCaching
  using Refinements

  extend self

  STORE_DIR = '.fcaching_store'.freeze
  Dir.mkdir(STORE_DIR) unless Dir.exist?(STORE_DIR)

  def fetch(key, max_age: nil, force: false)
    if block_given? and (existing_filenames(key, max_age: max_age).empty? or force)
      set(key, yield)
    end
    get(key, max_age: max_age)
  end

  def set(key, object)
    filesystem_guard(key)
    del(key)
    File.write("#{STORE_DIR}/#{key}_#{Time.now.iso8601}", Marshal.dump(object))
    true
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
      map{ |filename| "#{STORE_DIR}/#{filename}" }.
      then{ |filepaths| File.delete(*filepaths) }
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

  def filesystem_guard(string)
    raise "'#{string}' is not UNIX filesystem friendly !" if string[/[^\w_-]/]
  end
end
