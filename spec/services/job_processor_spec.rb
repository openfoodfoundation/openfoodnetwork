# frozen_string_literal: true

# We need to configure MiniRacer to allow forking.
# Otherwise this spec hangs on CI.
# https://github.com/rubyjs/mini_racer#fork-safety
require "mini_racer"
MiniRacer::Platform.set_flags!(:single_threaded)

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
  end
end
