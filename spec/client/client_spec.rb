# frozen_string_literal: true

require './client/client'

describe Client do
  subject { client }

  let(:client) { described_class.new }

  describe '#init' do
    it 'initializes' do
      subject
    end
  end

  describe '#work' do
    subject { client.work(line) }

    let(:line) { 'from a.csv' }

    before do
      allow_any_instance_of(ZMQ::Socket)
        .to receive(:bind)
        .and_return('test1')

      allow_any_instance_of(ZMQ::Socket)
        .to receive(:send_string)
        .and_return('test2')

      allow_any_instance_of(ZMQ::Socket)
        .to receive(:recv_string)
        .and_return('test3')
    end

    it 'forwards the line' do
      expect_any_instance_of(ZMQ::Socket).to receive(:send_string).once.with(line)

      subject
    end

    it 'prints the received data' do
      expect { subject }.to output("test3\n").to_stdout
    end
  end
end
