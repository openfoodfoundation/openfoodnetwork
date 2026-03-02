# frozen_string_literal: true

# This is the first example of testing concurrency in the Open Food Network.
# If we want to do this more often, we should look at:
#
#   https://github.com/forkbreak/fork_break
#
# The concurrency flag enables multiple threads to see the same database
# without isolated transactions.
RSpec.describe "Concurrent checkouts", concurrency: true do
  include AuthenticationHelper
  include ShopWorkflow

  let(:order_cycle) { create(:order_cycle) }
  let(:distributor) { order_cycle.distributors.first }
  let(:order) { create(:order, order_cycle:, distributor:) }
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
  let(:path) { checkout_update_path(:summary) }
  let(:params) { { format: :json } }

  before do
    # Create a valid order ready for checkout:
    create(:shipping_method, distributors: [distributor])
    variant = order_cycle.variants_distributed_by(distributor).first
    order.line_items << create(:line_item, variant:)

    # Transition cart to confirmation state:
    order.update(order_params)
    order.next # => address
    order.next # => delivery
    order.next # => payment
    order.next # => confirmation

    pick_order(order)
    login_as(order.user)
  end

  it "handles two concurrent orders successfully" do
    breakpoint.lock
    breakpoint_reached_counter = 0

    # Set a breakpoint after loading the order and before advancing the order's
    # state and making payments. If two requests reach this breakpoint at the
    # same time, they are in a race condition and bad things can happen.
    # Examples are processing payments twice or selling more than we have.
    allow_any_instance_of(CheckoutController).
      to receive(:advance_order_state).
      and_wrap_original do |method, *args|
      breakpoint_reached_counter += 1
      breakpoint.synchronize do
        # Wait here until the breakpoint is unlocked.
        # Hopefully only one thread gets here in that time.
        # The second thread is told by the controller to wait before
        # loading the order.
      end
      method.call(*args)
    end

    # Starting two checkout threads. The controller code will determine if
    # these two threads are synchronised correctly or run into a race condition.
    #
    # 1. If the controller synchronises correctly:
    #    The first thread locks required resources and then waits at the
    #    breakpoint. The second thread waits for the first one.
    # 2. If the controller fails to prevent the race condition:
    #    Both threads load required resources and wait at the breakpoint to do
    #    the same checkout action.
    threads = [
      Thread.new { put(path, params:) },
      Thread.new { put(path, params:) },
    ]

    # Wait for the first thread to reach the breakpoint:
    Timeout.timeout(1) do
      sleep 0.1 while breakpoint_reached_counter < 1
    end

    # Give the second thread a chance to reach the breakpoint, too.
    # But we hope that it waits for the first thread earlier and doesn't
    # reach the breakpoint yet.
    sleep 1
    expect(breakpoint_reached_counter).to eq 1

    # Let the requests continue and finish.
    breakpoint.unlock
    threads.each(&:join)

    # Verify that the checkout happened once.
    order.reload
    expect(order.completed?).to be true
    expect(order.payments.count).to eq 1
  end
end
