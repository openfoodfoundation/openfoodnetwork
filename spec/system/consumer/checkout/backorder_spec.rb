# frozen_string_literal: true

require "system_helper"

RSpec.describe "Checkout" do
  include ShopWorkflow
  include CheckoutHelper

  let(:variant) { order.variants.first }
  let(:order) { create(:order_ready_for_confirmation) }

  before do
    variant.semantic_links << SemanticLink.new(semantic_id: "https://product")
    pick_order order
    login_as create(:user)
  end

  it "triggers a backorder" do
    visit checkout_step_path(:summary)

    expect { place_order }.to enqueue_job BackorderJob
  end
end
