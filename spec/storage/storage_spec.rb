# frozen_string_literal: true

require './storage/storage'

describe Storage do
  subject { storage }

  let(:storage) { described_class.new }

  describe '#init' do
    it 'initializes the cache to an empty state' do
      expect(subject.cache).to be_empty
    end
  end

  describe '#work' do
    subject { storage.work(file) }

    let(:file) { 'foo' }

    context 'when no cached values' do
      before do
        allow(File).to receive(:read).and_return('test')
      end

      it { is_expected.to eq 'test' }

      it 'caches the file' do
        subject

        expect(storage.cache).to eq({ file => 'test' })
      end
    end

    context 'when one cached value' do
      before do
        allow(File).to receive(:read).and_return('test1', 'test2')

        storage.work('bar')
      end

      it { is_expected.to eq 'test2' }

      it 'caches the file' do
        subject

        expect(storage.cache).to eq({ 'bar' => 'test1', file => 'test2' })
      end
    end

    context 'when two cached value' do
      before do
        allow(File).to receive(:read).and_return('test1', 'test2', 'test3')

        storage.work('bar')
        storage.work('baz')
      end

      it { is_expected.to eq 'test3' }

      it 'caches the file' do
        subject

        expect(storage.cache).to eq({ 'baz' => 'test2', file => 'test3' })
      end
    end
  end
end
