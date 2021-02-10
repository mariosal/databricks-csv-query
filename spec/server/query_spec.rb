# frozen_string_literal: true

require './server/query'

describe Query do
  subject { query.commands }

  let(:string) { '' }
  let(:query) { described_class.new(string) }

  context 'when empty string' do
    it { is_expected.to be_empty }
  end

  context 'when invalid command' do
    let(:string) { 'foo bar boo' }

    it { is_expected.to be_empty }
  end

  describe '#from' do
    let(:string) { ' from  name ' }

    context 'when valid input' do
      it { is_expected.to eq [[:from, ['name']]] }
    end

    context 'when case-insensitive' do
      let(:string) { 'FrOm Name' }

      it { is_expected.to eq [[:from, ['Name']]] }
    end

    context 'when missing argument' do
      let(:string) { 'from' }

      it { is_expected.to be_empty }
    end
  end

  describe '#select' do
    let(:string) { ' select  name ' }

    context 'when valid input' do
      it { is_expected.to eq [[:select, [['name']]]] }

      context 'when multiple columns' do
        let(:string) { 'select name1,name2' }

        it { is_expected.to eq [[:select, [%w[name1 name2]]]] }
      end
    end

    context 'when different casing' do
      let(:string) { 'SeLeCt Name' }

      it { is_expected.to eq [[:select, [['Name']]]] }
    end

    context 'when missing argument' do
      let(:string) { 'select' }

      it { is_expected.to be_empty }
    end
  end

  describe '#take' do
    let(:string) { ' take  55 ' }

    context 'when valid input' do
      it { is_expected.to eq [[:take, [55]]] }
    end

    context 'when case-insensitive' do
      let(:string) { 'TaKe 12' }

      it { is_expected.to eq [[:take, [12]]] }
    end

    context 'when missing argument' do
      let(:string) { 'take' }

      it { is_expected.to be_empty }
    end

    context 'when not numeric argument' do
      let(:string) { 'take foo' }

      it { is_expected.to eq [[:take, [0]]] }
    end
  end

  describe '#orderby' do
    let(:string) { ' orderby name ' }

    context 'when valid input' do
      it { is_expected.to eq [[:order_by, ['name']]] }
    end

    context 'when case-insensitive' do
      let(:string) { 'Orderby Name' }

      it { is_expected.to eq [[:order_by, ['Name']]] }
    end

    context 'when missing argument' do
      let(:string) { 'orderby' }

      it { is_expected.to be_empty }
    end
  end

  describe '#join' do
    let(:string) { ' join foo bar' }

    context 'when valid input' do
      it { is_expected.to eq [[:join, %w[foo bar]]] }
    end

    context 'when case-insensitive' do
      let(:string) { 'Join Foo baR' }

      it { is_expected.to eq [[:join, %w[Foo baR]]] }
    end

    context 'when missing two arguments' do
      let(:string) { 'join' }

      it { is_expected.to be_empty }
    end

    context 'when missing one argument' do
      let(:string) { 'join' }

      it { is_expected.to be_empty }
    end
  end

  describe '#countby' do
    let(:string) { ' countby name ' }

    context 'when valid input' do
      it { is_expected.to eq [[:count_by, ['name']]] }
    end

    context 'when case-insensitive' do
      let(:string) { 'Countby Name' }

      it { is_expected.to eq [[:count_by, ['Name']]] }
    end

    context 'when missing argument' do
      let(:string) { 'countby' }

      it { is_expected.to be_empty }
    end
  end

  context 'when multiple arguments' do
    let(:string) { '  froM foo joiN bar boo' }

    context 'when valid input' do
      it { is_expected.to eq [[:from, ['foo']], [:join, %w[bar boo]]] }
    end

    context 'when invalid argument' do
      let(:string) { ' from foo join bar foo take' }

      it { is_expected.to be_empty }
    end
  end
end
