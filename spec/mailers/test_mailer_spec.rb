# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::TestMailer do
  subject(:mail) { described_class.test_email(order) }
  let(:user) { create(:user) }
  let(:order) { build(:order_with_distributor) }

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
    }.not_to raise_error
  end

  context "white labelling" do
    it_behaves_like 'email with inactive white labelling', :mail
    it_behaves_like 'non-customer facing email with active white labelling', :mail
  end
end
