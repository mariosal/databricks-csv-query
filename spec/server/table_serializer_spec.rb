# frozen_string_literal: true

require './server/table'
require './server/table_serializer'

describe TableSerializer do
  subject { described_class.new(table).to_s }

  let(:attributes) { [] }
  let(:rows) { [] }
  let(:table) do
    table = Table.new
    table.attributes = attributes
    table.rows = rows
    table
  end

  context 'when no attributes' do
    let(:attributes) { [] }
    let(:rows) { [['invalid']] }

    it { is_expected.to be_empty }
  end

  context 'when no rows' do
    let(:attributes) { %w[foo bar] }
    let(:rows) { [] }

    it { is_expected.to eq "foo,bar\n" }
  end

  context 'when both attributes and rows' do
    let(:attributes) { %w[foo bar] }
    let(:rows) { [%w[fizz buzz], %w[fizzbuzz test]] }

    it { is_expected.to eq "foo,bar\nfizz,buzz\nfizzbuzz,test\n" }
  end
end
