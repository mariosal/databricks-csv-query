# frozen_string_literal: true

# The Query class is responsible for deserializing the String input given by the
# Client.
class Query
  # Acceptable commands mapped to method symbols
  WHITELIST_COMMANDS = {
    'from' => :from,
    'select' => :select,
    'take' => :take,
    'orderby' => :order_by,
    'join' => :join,
    'countby' => :count_by
  }.freeze

  # `#commands` returns a Array containing all commands deserialized in the
  # following format:
  #
  #   [
  #     { name: String, args: Array }
  #   ]
  #
  attr_reader :commands

  def initialize(string)
    reset

    i = 0
    tokens = string.strip.split
    while i < tokens.size
      name = WHITELIST_COMMANDS[tokens[i].downcase]

      if name.nil? || i + 1 >= tokens.size
        reset
        return
      end

      command = [name]

      command <<
        case name
        when :select
          [tokens[i + 1].split(',')]
        when :take
          [tokens[i + 1].to_i]
        when :join
          if i + 2 >= tokens.size
            reset
            return
          end

          args = [tokens[i + 1], tokens[i + 2]]
          i += 1
          args
        else
          [tokens[i + 1]]
        end

      @commands << command
      i += 2
    end
  end

  def reset
    @commands = []
  end
end
