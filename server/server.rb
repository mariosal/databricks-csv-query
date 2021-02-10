# frozen_string_literal: true

require 'warning'

# Ignoring ZeroMQ gem warnings
Gem.path.each do |path|
  Warning.ignore(//, path)
end

require '0mq'

require './server/query'
require './server/table'
require './server/table_serializer'

require './lib/settings'

# The Server receives the user's raw input from the Client via a ZeroMQ socket
# and:
#   - Calls the Query object contructor to parse the input
#   - Calls the respective Table methods which actually compute the results
#   - Returns the results to the Client
class Server
  include Settings

  def initialize
    # The Server defines the means of communication between the Table class and
    # the Storage service.
    Table.class_variable_set(:@@socket, storage_socket)
  end

  def run
    stty_state = `stty -g`.chomp

    loop do
      # Blocking until reception
      string = client_socket.recv_string

      client_socket.send_string(work(string))
    rescue Interrupt
      system('stty', stty_state) # Restore the TTY state
      exit
    end
  end

  def client_socket
    return @client_socket if defined?(@client_socket)

    @client_socket = ZMQ::Socket.new(ZMQ::REP)
    @client_socket.connect(settings['queue_host'])
    @client_socket
  end

  def storage_socket
    return @storage_socket if defined?(@storage_socket)

    @storage_socket = ZMQ::Socket.new(ZMQ::REQ)
    @storage_socket.bind(settings['storage_host'])
    @storage_socket
  end

  # @param string [String] The raw input string
  #
  # @return [String] A serialized CSV string
  def work(string)
    query = Query.new(string)
    table = Table.new

    query.commands.each do |name, args|
      table.public_send(name, *args)
    end

    TableSerializer.new(table)
  end
end

server = Server.new
server.run if ENV['RACK_ENV'] != 'test'
