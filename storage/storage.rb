# frozen_string_literal: true

require 'warning'

Gem.path.each do |path|
  Warning.ignore(//, path)
end

require '0mq'
require 'zaru'

require './lib/settings'

# The Storage service connect to the Server via a ZeroMQ socket, thus it can be
# extented to fetch documents from source other than the File system. Such as,
# the Web, a Database, etc.
#
# The Storage service implements a simple FIFO cache mechanism to avoid disk I/O
class Storage
  include Settings

  MAX_CACHE_ELEMENTS = 2

  attr_reader :cache

  def initialize
    @cache = {}
  end

  def run
    stty_state = `stty -g`.chomp

    loop do
      # Blocking until reception
      file_name = socket.recv_string

      socket.send_string(work(file_name))
    rescue Interrupt
      system('stty', stty_state) # Restore the TTY state
      exit
    end
  end

  def socket
    return @socket if defined?(@socket)

    @socket = ZMQ::Socket.new(ZMQ::REP)
    @socket.connect(settings['storage_host'])
    @socket
  end

  def work(file_name)
    sanitized_file_name = Zaru.sanitize!(file_name)
    return @cache[sanitized_file_name] if @cache.key?(sanitized_file_name)

    file_path = "#{settings['data_path']}/#{sanitized_file_name}"

    begin
      content = File.read(file_path)
      @cache[sanitized_file_name] = content

      # Remove the first key that was cached
      @cache = @cache.to_a[1..].to_h if @cache.size > MAX_CACHE_ELEMENTS

      content
    rescue Errno::ENOENT, Errno::EACCES
      ''
    end
  end
end

storage = Storage.new
storage.run if ENV['RACK_ENV'] != 'test'
