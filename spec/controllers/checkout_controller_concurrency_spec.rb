# frozen_string_literal: true

require 'spec_helper'

# This is the first example of testing concurrency in the Open Food Network.
# If we want to do this more often, we should look at:
#
#   https://github.com/forkbreak/fork_break
#
# The concurrency flag enables multiple threads to see the same database
# without isolated transactions.
describe CheckoutController, concurrency: true, type: :controller do
  let(:order_cycle) { create(:order_cycle) }
  let(:distributor) { order_cycle.distributors.first }
  let(:order) { create(:order, order_cycle: order_cycle, distributor: distributor) }
  let(:address) { create(:address) }
  let(:payment_method) { create(:payment_method, distributors: [distributor]) }
  let(:breakpoint) { Mutex.new }

  let(:address_params) { address.attributes.except("id") }
  let(:order_params) {
    {
      "payments_attributes" => [
        {
          "payment_method_id" => payment_method.id,
          "amount" => order.total
        }
      ],
      "bill_address_attributes" => address_params,
      "ship_address_attributes" => address_params,
    }
  }

  before do
    # Create a valid order ready for checkout:
    create(:shipping_method, distributors: [distributor])
    variant = order_cycle.variants_distributed_by(distributor).first
    order.line_items << create(:line_item, variant: variant)

    # Set up controller environment:
    session[:order_id] = order.id
    allow(controller).to receive(:spree_current_user).and_return(order.user)
    allow(controller).to receive(:current_distributor).and_return(order.distributor)
    allow(controller).to receive(:current_order_cycle).and_return(order.order_cycle)
  end

  it "handles two concurrent orders successfully" do
    # New threads start running straight away. The breakpoint is after loading
    # the order and before advancing the order's state and making payments.
    breakpoint.lock
    expect(controller).to receive(:fire_event).with("spree.checkout.update") do
      breakpoint.synchronize {}
      # This is what fire_event does.
      # I did not find out how to call the original code otherwise.
      ActiveSupport::Notifications.instrument("spree.checkout.update")
    end

    # Starting two checkout threads. The controller code will determine if
    # these two threads are synchronised correctly or run into a race condition.
    #
    # 1. If the controller synchronises correctly:
    #    The first thread locks required resources and then waits at the
    #    breakpoint. The second thread waits for the first one.
    # 2. If the controller fails to prevent the race condition:
    #    Both threads load required resources and wait at the breakpoint to do
    #    the same checkout action. This will lead to (random) errors.
    #
    #    I observed:
    #    ActiveRecord::RecordNotUnique: duplicate key value violates unique
    #    constraint "index_spree_shipments_on_order_id"
    #    on `INSERT INTO "spree_shipments" ...`.
    #
    #    Or:
    #    ActiveRecord::InvalidForeignKey: insert or update on table
    #    "spree_orders" violates foreign key constraint
    #    "spree_orders_customer_id_fk"
    threads = [
      Thread.new { spree_post :update, format: :json, order: order_params },
      Thread.new { spree_post :update, format: :json, order: order_params },
    ]
    # Let the threads run again. They should not be in a race condition.
    breakpoint.unlock
    # Wait for both threads to finish.
    threads.each(&:join)
    order.reload

    # When the spec passes, both threads have the same result. The user should
    # see the order page. This is basically verifying a "double click"
    # scenario.
    expect(response.status).to eq(200)
    expect(response.body).to eq({ path: spree.order_path(order) }.to_json)
    expect(order.payments.count).to eq 1
    expect(order.completed?).to be true
  end
end
