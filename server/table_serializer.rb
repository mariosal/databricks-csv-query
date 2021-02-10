# frozen_string_literal: true

# The TableSerializer consumes a Table object and produces a CSV string output.
class TableSerializer
  def initialize(table)
    @table = table
  end

  def to_s
    return '' if @table.attributes.empty?

    CSV.generate do |csv|
      csv << @table.attributes

      @table.rows.each do |row|
        csv << row
      end
    end
  end
end
