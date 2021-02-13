# frozen_string_literal: true

require 'warning'

# Silence ZeroMQ library warnings
Gem.path.each do |path|
  Warning.ignore(//, path)
end

require '0mq'
require 'readline'

require './lib/settings'

# The Client initializes a Readline prompt which transmits the raw user's input
# to the Server using a ZeroMQ socket.
class Client
  include Settings

  # A String which is displayed at the start of each prompt line
  PROMPT_PREFIX = '> '

  # Configure whether the prompt will save the history in memory
  SAVE_PROMPT_HISTORY = true

  def run
    # Save the current TTY state for restoring later
    stty_state = `stty -g`.chomp

    loop do
      line = Readline.readline(PROMPT_PREFIX, SAVE_PROMPT_HISTORY)
      break if !line

      work(line)
    rescue Interrupt
      system('stty', stty_state) # Restore the TTY state
      exit
    end
  end

  def socket
    return @socket if defined?(@socket)

    @socket = ZMQ::Socket.new(ZMQ::REQ)
    @socket.connect(settings['queue_host'])
    @socket
  end

  def work(line)
    socket.send_string(line)

    # Blocking until reception
    puts socket.recv_string
  end
end

client = Client.new
client.run if ENV['RACK_ENV'] != 'test'
