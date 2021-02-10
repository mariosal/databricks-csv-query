# frozen_string_literal: true

require './server/table'

describe Table do
  subject { query.commands }

  let(:table) { described_class.new }

  describe '#init' do
    it 'initializes correctly' do
      expect(table.attributes).to eq []
      expect(table.index).to eq({})
      expect(table.rows).to eq []
    end
  end

  describe '#reset' do
    before do
      table.attributes = ['foo']
      table.rows = [['bar']]
    end

    it 'resets the data' do
      expect(table.attributes).to eq ['foo']
      expect(table.index).to eq({ 'foo' => 0 })
      expect(table.rows).to eq [['bar']]

      table.reset

      expect(table.attributes).to eq []
      expect(table.index).to eq({})
      expect(table.rows).to eq []
    end
  end

  describe '#select' do
    context 'when selecting one column' do
      before do
        table.attributes = %w[foo bar zar]
        table.rows = [%w[a b c], %w[d e f]]

        table.select(['zar'])
      end

      it 'selects that column' do
        expect(table.attributes).to eq ['zar']
        expect(table.index).to eq({ 'zar' => 0 })
        expect(table.rows).to eq [['c'], ['f']]
      end
    end

    context 'when selecting two columns' do
      before do
        table.attributes = %w[foo bar zar]
        table.rows = [%w[a b c], %w[d e f]]

        table.select(%w[zar foo])
      end

      it 'selects the two columns' do
        expect(table.attributes).to eq %w[zar foo]
        expect(table.index).to eq({ 'zar' => 0, 'foo' => 1 })
        expect(table.rows).to eq [%w[c a], %w[f d]]
      end
    end

    context 'when selecteing a non-existing column' do
      before do
        table.attributes = %w[foo bar zar]
        table.rows = [%w[a b c], %w[d e f]]

        table.select(['buzz'])
      end

      it 'selects that column' do
        expect(table.attributes).to eq ['buzz']
        expect(table.index).to eq({ 'buzz' => 0 })
        expect(table.rows).to eq [[nil], [nil]]
      end
    end
  end

  describe '#take' do
    context 'when taking a positive number' do
      before do
        table.attributes = %w[foo bar zar]
        table.rows = [%w[a b c], %w[d e f]]

        table.take(1)
      end

      it 'selects one row' do
        expect(table.attributes).to eq %w[foo bar zar]
        expect(table.index).to eq({ 'foo' => 0, 'bar' => 1, 'zar' => 2 })
        expect(table.rows).to eq [%w[a b c]]
      end
    end

    context 'when taking zero' do
      before do
        table.attributes = %w[foo bar zar]
        table.rows = [%w[a b c], %w[d e f]]

        table.take(0)
      end

      it 'selects none' do
        expect(table.attributes).to eq %w[foo bar zar]
        expect(table.index).to eq({ 'foo' => 0, 'bar' => 1, 'zar' => 2 })
        expect(table.rows).to eq []
      end
    end

    context 'when taking less than zero' do
      before do
        table.attributes = %w[foo bar zar]
        table.rows = [%w[a b c], %w[d e f]]

        table.take(-10)
      end

      it 'selects none' do
        expect(table.attributes).to eq %w[foo bar zar]
        expect(table.index).to eq({ 'foo' => 0, 'bar' => 1, 'zar' => 2 })
        expect(table.rows).to eq []
      end
    end

    context 'when taking a non-numeric' do
      before do
        table.attributes = %w[foo bar zar]
        table.rows = [%w[a b c], %w[d e f]]

        table.take('foo')
      end

      it 'selects none' do
        expect(table.attributes).to eq %w[foo bar zar]
        expect(table.index).to eq({ 'foo' => 0, 'bar' => 1, 'zar' => 2 })
        expect(table.rows).to eq []
      end
    end
  end

  describe '#order_by' do
    context 'when ordering by an existing column' do
      before do
        table.attributes = %w[foo zar]
        table.rows = [['a', 1], ['b', 2]]

        table.order_by('zar')
      end

      it 'orders correctly' do
        expect(table.attributes).to eq %w[foo zar]
        expect(table.index).to eq({ 'foo' => 0, 'zar' => 1 })
        expect(table.rows).to eq [['b', 2], ['a', 1]]
      end
    end

    context 'when ordering by an non-existing column' do
      before do
        table.attributes = %w[foo zar]
        table.rows = [['a', 1], ['b', 2]]

        table.order_by('foozar')
      end

      it 'does nothing' do
        expect(table.attributes).to eq %w[foo zar]
        expect(table.index).to eq({ 'foo' => 0, 'zar' => 1 })
        expect(table.rows).to eq [['a', 1], ['b', 2]]
      end
    end

    context 'when values are not numberic' do
      before do
        table.attributes = %w[foo zar]
        table.rows = [['a', nil], ['b', 2]]

        table.order_by('zar')
      end

      it 'treats them as infinity' do
        expect(table.attributes).to eq %w[foo zar]
        expect(table.index).to eq({ 'foo' => 0, 'zar' => 1 })
        expect(table.rows).to eq [['b', 2], ['a', nil]]
      end
    end
  end

  describe '#count_by' do
    context 'when counting by an existing column' do
      before do
        table.attributes = %w[foo zar boo]
        table.rows = [[2, 'c', 3], [1, 'a', 'b'], [2, 'b', 50], [3, 'a', 2]]

        table.count_by('zar')
      end

      it 'counts correctly' do
        expect(table.attributes).to eq %w[zar count]
        expect(table.index).to eq({ 'zar' => 0, 'count' => 1 })
        expect(table.rows).to eq [['c', 1], ['a', 2], ['b', 1]]
      end
    end

    context 'when counting by an non-existing column' do
      before do
        table.attributes = %w[foo zar boo]
        table.rows = [[2, 'c', 3], [1, 'a', 'b'], [2, 'b', 50], [3, 'a', 2]]

        table.count_by('fizz')
      end

      it 'counts correctly' do
        expect(table.attributes).to eq %w[fizz count]
        expect(table.index).to eq({ 'fizz' => 0, 'count' => 1 })
        expect(table.rows).to eq []
      end
    end
  end

  describe '#hash_join' do
    context 'when no duplicates and existing column' do
      let(:left_table) do
        left_table = described_class.new
        left_table.attributes = %w[orderid customerid employerid]
        left_table.rows = [[10_308, 2, 7], [10_309, 37, 3], [10_310, 3, 8]]
        left_table
      end

      let(:right_table) do
        right_table = described_class.new
        right_table.attributes = %w[customername customerid contactname]
        right_table.rows = [['all', 1, 'mar'], ['ana', 2, 'ana'], ['ana', 3, 'lol']]
        right_table
      end

      it 'joins correctly' do
        new_table = described_class.new
        new_table.hash_join(left_table, right_table, 'customerid')

        expect(new_table.attributes).to eq %w[orderid customerid employerid customername contactname]
        expect(new_table.index).to eq({ 'orderid' => 0, 'customerid' => 1, 'employerid' => 2, 'customername' => 3,
                                        'contactname' => 4 })
        expect(new_table.rows).to match_array [[10_308, 2, 7, 'ana', 'ana'], [10_310, 3, 8, 'ana', 'lol']]
      end
    end

    context 'when non-existing column' do
      let(:left_table) do
        left_table = described_class.new
        left_table.attributes = %w[orderid customerid employerid]
        left_table.rows = [[10_308, 2, 7], [10_309, 37, 3], [10_310, 3, 8]]
        left_table
      end

      let(:right_table) do
        right_table = described_class.new
        right_table.attributes = %w[customername customerid contactname]
        right_table.rows = [['all', 1, 'mar'], ['ana', 2, 'ana'], ['ana', 3, 'lol']]
        right_table
      end

      it 'resets the table' do
        new_table = described_class.new
        new_table.hash_join(left_table, right_table, 'foo')

        expect(new_table.attributes).to eq []
        expect(new_table.index).to eq({})
        expect(new_table.rows).to eq []
      end
    end

    context 'when duplicates and existing column' do
      let(:left_table) do
        left_table = described_class.new
        left_table.attributes = %w[orderid customerid employerid]
        left_table.rows = [[10_308, 2, 7], [10_309, 37, 3], [10_310, 3, 8]]
        left_table
      end

      let(:right_table) do
        right_table = described_class.new
        right_table.attributes = %w[customername customerid contactname]
        right_table.rows = [['all', 3, 'mar'], ['ana', 2, 'ana'], ['mar', 2, 'lol']]
        right_table
      end

      it 'joins correctly' do
        new_table = described_class.new
        new_table.hash_join(left_table, right_table, 'customerid')

        expect(new_table.attributes).to eq %w[orderid customerid employerid customername contactname]
        expect(new_table.index).to eq({ 'orderid' => 0, 'customerid' => 1, 'employerid' => 2, 'customername' => 3,
                                        'contactname' => 4 })
        expect(new_table.rows).to match_array [[10_308, 2, 7, 'ana', 'ana'], [10_308, 2, 7, 'mar', 'lol'],
                                               [10_310, 3, 8, 'all', 'mar']]
      end
    end
  end

  describe '#sort_merge' do
    context 'when no duplicates and existing column' do
      let(:left_table) do
        left_table = described_class.new
        left_table.attributes = %w[orderid customerid employerid]
        left_table.rows = [[10_308, 2, 7], [10_309, 37, 3], [10_310, 3, 8]]
        left_table
      end

      let(:right_table) do
        right_table = described_class.new
        right_table.attributes = %w[customername customerid contactname]
        right_table.rows = [['all', 1, 'mar'], ['ana', 2, 'ana'], ['ana', 3, 'lol']]
        right_table
      end

      it 'joins correctly' do
        new_table = described_class.new
        new_table.sort_merge(left_table, right_table, 'customerid')

        expect(new_table.attributes).to eq %w[orderid customerid employerid customername contactname]
        expect(new_table.index).to eq({ 'orderid' => 0, 'customerid' => 1, 'employerid' => 2, 'customername' => 3,
                                        'contactname' => 4 })
        expect(new_table.rows).to match_array [[10_308, 2, 7, 'ana', 'ana'], [10_310, 3, 8, 'ana', 'lol']]
      end
    end

    context 'when non-existing column' do
      let(:left_table) do
        left_table = described_class.new
        left_table.attributes = %w[orderid customerid employerid]
        left_table.rows = [[10_308, 2, 7], [10_309, 37, 3], [10_310, 3, 8]]
        left_table
      end

      let(:right_table) do
        right_table = described_class.new
        right_table.attributes = %w[customername customerid contactname]
        right_table.rows = [['all', 1, 'mar'], ['ana', 2, 'ana'], ['ana', 3, 'lol']]
        right_table
      end

      it 'resets the table' do
        new_table = described_class.new
        new_table.sort_merge(left_table, right_table, 'foo')

        expect(new_table.attributes).to eq []
        expect(new_table.index).to eq({})
        expect(new_table.rows).to eq []
      end
    end

    context 'when duplicates and existing column' do
      let(:left_table) do
        left_table = described_class.new
        left_table.attributes = %w[orderid customerid employerid]
        left_table.rows = [[10_308, 2, 7], [10_309, 37, 3], [10_310, 3, 8]]
        left_table
      end

      let(:right_table) do
        right_table = described_class.new
        right_table.attributes = %w[customername customerid contactname]
        right_table.rows = [['all', 3, 'mar'], ['ana', 2, 'ana'], ['mar', 2, 'lol']]
        right_table
      end

      it 'joins correctly' do
        new_table = described_class.new
        new_table.sort_merge(left_table, right_table, 'customerid')

        expect(new_table.attributes).to eq %w[orderid customerid employerid customername contactname]
        expect(new_table.index).to eq({ 'orderid' => 0, 'customerid' => 1, 'employerid' => 2, 'customername' => 3,
                                        'contactname' => 4 })
        expect(new_table.rows).to match_array [[10_308, 2, 7, 'ana', 'ana'], [10_308, 2, 7, 'mar', 'lol'],
                                               [10_310, 3, 8, 'all', 'mar']]
      end
    end
  end
end
