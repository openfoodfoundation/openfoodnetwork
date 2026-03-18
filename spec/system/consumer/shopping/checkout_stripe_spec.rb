# frozen_string_literal: true

require 'system_helper'

RSpec.describe "Check out with Stripe" do
  describe "using Stripe SCA" do
    context "with guest checkout" do
      context "when the card is accepted" do
        it "completes checkout successfully"
      end

      context "when the card is rejected" do
        it "shows an error message from the Stripe response"
      end

      context "when the card needs extra SCA authorization" do
        describe "and the authorization succeeds" do
          it "completes checkout successfully"
        end

        describe "and the authorization fails" do
          it "shows an error message from the Stripe response"
        end
      end

      context "with multiple payment attempts; one failed and one succeeded" do
        it "records failed payment attempt and allows order completion"
      end
    end

    context "with a logged in user" do
      context "saving a card and re-using it" do
        it "allows saving a card and re-using it"
      end
    end
  end
end
