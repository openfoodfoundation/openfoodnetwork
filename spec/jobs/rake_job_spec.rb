# frozen_string_literal: true

require "tasks/data/remove_transient_data"

RSpec.describe RakeJob do
  let(:task_string) { "ofn:data:remove_transient_data" }

  it "calls the removal service" do
    expect(RemoveTransientData).to receive(:new).and_call_original
    RakeJob.perform_now(task_string)
  end

  it "can be called several times" do
    expect(RemoveTransientData).to receive(:new).twice.and_call_original
    RakeJob.perform_now(task_string)
    RakeJob.perform_now(task_string)
  end
end
