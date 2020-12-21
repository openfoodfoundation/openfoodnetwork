# frozen_string_literal: true

RSpec::Matchers.define :send_confirmation_instructions do
  match do |event_proc|
    expect(&event_proc).to change { ActionMailer::Base.deliveries.count }.by 1

    message = ActionMailer::Base.deliveries.last
    expect(message.subject).to eq "Please confirm your OFN account"
  end

  def supports_block_expectations?
    true
  end
end
