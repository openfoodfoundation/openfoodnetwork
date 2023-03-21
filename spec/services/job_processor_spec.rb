# frozen_string_literal: true

require 'spec_helper'

class TestJob < ApplicationJob
  def initialize
    @file = Tempfile.new("test-job-result")
    super
  end

  def perform(message)
    @file.write(message)
  end

  def result
    @file.rewind
    @file.read
  end
end

describe JobProcessor do
  describe ".perform_forked" do
    let(:job) { TestJob.new }

    it "executes a job" do
      JobProcessor.perform_forked(job, "hello")

      expect(job.result).to eq "hello"
    end

    describe "with other unrelated children" do
      let(:start_time) { Time.zone.now }
      let(:end_time) { Time.zone.now }

      # We made a mistake waiting for all forked processes.
      # Now starting an unrelated process in a similar way.
      around do |example|
        start_time
        other_process = fork { sleep 10 }
        example.run
        Process.kill("QUIT", other_process)
      end

      it "returns as soon as the job is done" do
        JobProcessor.perform_forked(job, "hello")

        expect(end_time).to be_within(10.seconds).of start_time
      end
    end

    describe "when forking fails" do
      before do
        # We can't make `fork` fail and choose the method call before it.
        expect(ENV).to receive(:fetch).and_raise("Test Error")
      end

      it "raises the causing error" do
        expect { JobProcessor.perform_forked(job) }.to raise_error "Test Error"
      end
    end
  end
end
