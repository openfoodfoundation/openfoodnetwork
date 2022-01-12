# frozen_string_literal: true

require 'spec_helper'

describe Spree::TestMailer do
  let(:user) { create(:user) }

  context ":from not set explicitly" do
    it "falls back to spree config" do
      message = Spree::TestMailer.test_email(user)
      expect(message.from).to eq [Spree::Config[:mails_from]]
    end
  end

  it "confirm_email accepts a user id as an alternative to a User object" do
    expect(Spree::User).to receive(:find).with(user.id).and_return(user)
    expect {
      Spree::TestMailer.test_email(user.id).deliver_now
    }.to_not raise_error
  end
end
