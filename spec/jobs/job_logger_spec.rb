# frozen_string_literal: false

require 'spec_helper'

describe JobLogger do
  describe '.logger' do
    it 'passes the message to the Logger instance' do
      job_logger = instance_double(::Logger)
      allow(job_logger).to receive(:formatter=)
      allow(job_logger).to receive(:info)
      allow(Delayed::Worker).to receive(:logger) { job_logger }

      JobLogger.logger.info('log message')

      expect(job_logger).to have_received(:info).with('log message')
    end
  end

  describe JobLogger::Formatter do
    describe '#call' do
      it 'outputs timestamps, progname and message' do
        timestamp = DateTime.new(2020, 5, 6, 22, 36, 0)
        log_line = JobLogger::Formatter.new.call(nil, timestamp, 'progname', 'message')
        expect(log_line).to eq("2020-05-06T22:36:00+0000: message\n")
      end
    end
  end
end
