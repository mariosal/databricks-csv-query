# frozen_string_literal: true

require 'csv'
require 'set'

require './lib/settings'

# The Table class is responsible for actually implementing the Query language.
# It interacts with the Storage service using a ZeroMQ socket, thus it is
# agnostic on where the data live.
#
# Each Query command is immediately applied to the data, there is no lazy
# evaluation. The internal representation consists of the following data:
#
#   - attributes: The columns of the dataset as an Array
#   - rows: The rows of the dataset as an Array
#   - index: A dictionary from the attributes (strings) to the position in the
#            `rows` array
class Table
  extend Settings

  # The Socket class variable is set on the Server class
  @@socket = nil

  attr_accessor :rows
  attr_reader :attributes, :index

  def initialize
    reset
  end

  def reset
    @attributes = []
    @index = {}

    @rows = []
  end

  def attributes=(columns)
    @attributes = columns
    @index = columns.each_with_index.to_h
  end

  def from(file_name)
    @@socket.send_string(file_name)

    # Blocking until reception
    response = @@socket.recv_string
    return if response.empty?

    content = CSV.parse(response, converters: :numeric)
    self.attributes, *@rows = content
  end

  def select(columns)
    @rows.map! do |row|
      @index.values_at(*columns).map do |column|
        row[column] if !column.nil?
      end
    end

    self.attributes = columns
  end

  # In case of invalid or negative input, 0 is being used instead
  def take(limit)
    limit = 0 if !limit.is_a?(Numeric)

    @rows = @rows.take([0, limit].max)
  end

  # In case of a non-numeric value, the comparison is done using `nil` as value
  def order_by(column)
    return if !@index.key?(column)

    @rows.sort_by! do |row|
      value = row[@index[column]]

      if value.is_a?(Numeric)
        -value
      else
        Float::INFINITY
      end
    end
  end

  # Hash join
  def join(file_name, column)
    left = self

    right = self.class.new
    right.from(file_name)

    sort_merge(left, right, column)
  end

  def sort_merge(left, right, column)
    left_index = left.index[column]
    right_index = right.index[column]
    return reset if left_index.nil? || right_index.nil?

    left_sorted = left.rows.sort_by do |row|
      row[left_index]
    end
    right_sorted = right.rows.sort_by do |row|
      row[right_index]
    end

    joined_rows = []
    (left_subset, left_key) = advance(left_sorted, left_index)
    (right_subset, right_key) = advance(right_sorted, right_index)
    while !left_subset.empty? && !right_subset.empty?
      if left_key == right_key
        left_subset.each do |left_row|
          right_subset.each do |right_row|
            joined_rows << left_row + right_row.reject.with_index do |_, index|
              index == right_index
            end
          end
        end

        (left_subset, left_key) = advance(left_sorted, left_index)
        (right_subset, right_key) = advance(right_sorted, right_index)
      elsif left_key < right_key
        (left_subset, left_key) = advance(left_sorted, left_index)
      else
        (right_subset, right_key) = advance(right_sorted, right_index)
      end
    end

    self.attributes = left.attributes + (right.attributes - [column])
    @rows = joined_rows
  end

  def advance(sorted, index)
    subset = Set.new
    key = sorted.dig(0, index)
    while !sorted.empty? && sorted[0][index] == key
      subset << sorted[0]
      sorted.shift # Amortized constant
    end

    [subset, key]
  end

  def hash_join(left, right, column)
    left_index = left.index[column]
    right_index = right.index[column]
    return reset if left_index.nil? || right_index.nil?

    right_hash = right.rows.group_by do |right_row|
      right_row[right.index[column]]
    end

    joined_rows = []
    left.rows.each do |left_row|
      value = left_row[left.index[column]]

      right_hash[value]&.each do |right_row|
        joined_rows << left_row + right_row.reject.with_index do |_, index|
          index == right.index[column]
        end
      end
    end

    self.attributes = left.attributes + (right.attributes - [column])
    @rows = joined_rows
  end

  def count_by(column)
    counts = counts(column)

    self.attributes = [column, 'count']
    @rows = counts.to_a
  end

  def counts(column)
    return {} if !index.key?(column)

    @rows.each_with_object(Hash.new(0)) do |row, counts|
      value = row[@index[column]]

      counts[value] += 1
    end
  end
end
