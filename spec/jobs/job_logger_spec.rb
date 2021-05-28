# frozen_string_literal: true

require 'spec_helper'

describe SubsLogger do
  describe '.logger' do
    it "returns a Ruby's logger instance" do
      expect(SubsLogger.logger).to respond_to(:info)
    end

    it 'returns custom formatted logger instance' do
      expect(SubsLogger.logger.formatter).to be_instance_of(SubsLogger::Formatter)
    end
  end

  describe SubsLogger::Formatter do
    describe '#call' do
      it 'outputs timestamps, progname and message' do
        timestamp = DateTime.new(2020, 5, 6, 22, 36, 0)
        log_line = SubsLogger::Formatter.new.call(nil, timestamp, 'progname', 'message')
        expect(log_line).to eq("2020-05-06T22:36:00+0000: message\n")
      end
    end
  end
end
