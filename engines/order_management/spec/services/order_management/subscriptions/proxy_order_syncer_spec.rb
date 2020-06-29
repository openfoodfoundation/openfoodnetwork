# frozen_string_literal: true

require 'spec_helper'

module OrderManagement
  module Subscriptions
    describe ProxyOrderSyncer do
      describe "initialization" do
        let!(:subscription) { create(:subscription) }

        it "raises an error when initialized with an object
            that is not a Subscription or an ActiveRecord::Relation" do
          expect{ ProxyOrderSyncer.new(subscription) }.to_not raise_error
          expect{ ProxyOrderSyncer.new(Subscription.where(id: subscription.id)) }.to_not raise_error
          expect{ ProxyOrderSyncer.new("something") }.to raise_error RuntimeError
        end
      end

      describe "#sync!" do
        let(:now) { Time.zone.now }
        let(:schedule) { create(:schedule, order_cycles: [oc]) }

        let(:closed_oc) {
          create(:simple_order_cycle, orders_open_at: now - 1.minute, orders_close_at: now)
        }
        let(:open_oc_closes_before_begins_at_oc) { # Open, but closes before begins at
          create(:simple_order_cycle,
                 orders_open_at: now - 1.minute, orders_close_at: now + 59.seconds)
        }
        let(:open_oc) { # Open & closes between begins at and ends at
          create(:simple_order_cycle,
                 orders_open_at: now - 1.minute, orders_close_at: now + 90.seconds)
        }
        let(:upcoming_closes_before_begins_at_oc) { # Upcoming, but closes before begins at
          create(:simple_order_cycle,
                 orders_open_at: now + 30.seconds, orders_close_at: now + 59.seconds)
        }
        let(:upcoming_closes_on_begins_at_oc) { # Upcoming & closes on begins at
          create(:simple_order_cycle,
                 orders_open_at: now + 30.seconds, orders_close_at: now + 1.minute)
        }
        let(:upcoming_closes_on_ends_at_oc) { # Upcoming & closes on ends at
          create(:simple_order_cycle,
                 orders_open_at: now + 30.seconds, orders_close_at: now + 2.minutes)
        }
        let(:upcoming_closes_after_ends_at_oc) { # Upcoming & closes after ends at
          create(:simple_order_cycle,
                 orders_open_at: now + 30.seconds, orders_close_at: now + 121.seconds)
        }

        let(:subscription) {
          build(:subscription, begins_at: now + 1.minute, ends_at: now + 2.minutes)
        }
        let(:proxy_orders) { subscription.reload.proxy_orders }
        let(:order_cycles) { proxy_orders.map(&:order_cycle) }
        let(:syncer) { ProxyOrderSyncer.new(subscription) }

        context "when the subscription is not persisted" do
          let(:schedule) { create(:schedule, order_cycles: [oc]) }
          let(:subscription) do
            build(
              :subscription,
              begins_at: now + 1.minute,
              ends_at: now + 2.minutes,
              schedule: schedule
            )
          end

          context "and the schedule includes a closed oc (ie. closed before opens_at)" do
            let!(:oc) { closed_oc }

            it "does not create a new proxy order for that oc" do
              expect{ subscription.save! }.to_not change(ProxyOrder, :count).from(0)
              expect(order_cycles).to_not include oc
            end
          end

          context "and the schedule includes an open oc that closes before begins_at" do
            let!(:oc) { open_oc_closes_before_begins_at_oc }

            it "does not create a new proxy order for that oc" do
              expect{ subscription.save! }.to_not change(ProxyOrder, :count).from(0)
              expect(order_cycles).to_not include oc
            end
          end

          context "and the schedule has an open OC that closes between begins_at and ends_at" do
            let!(:oc) { open_oc }

            it "creates a new proxy order for that oc" do
              syncer.sync!

              expect{ subscription.save! }.to change(ProxyOrder, :count).from(0).to(1)
              expect(subscription.reload.proxy_orders.map(&:order_cycle)).to include oc
            end
          end

          context "and the schedule includes upcoming oc that closes before begins_at" do
            let!(:oc) { upcoming_closes_before_begins_at_oc }

            it "does not create a new proxy order for that oc" do
              expect{ subscription.save! }.to_not change(ProxyOrder, :count).from(0)
              expect(order_cycles).to_not include oc
            end
          end

          context "and the schedule includes upcoming oc that closes on begins_at" do
            let!(:oc) { upcoming_closes_on_begins_at_oc }

            it "creates a new proxy order for that oc" do
              syncer.sync!

              expect{ subscription.save! }.to change(ProxyOrder, :count).from(0).to(1)
              expect(subscription.reload.proxy_orders.map(&:order_cycle)).to include oc
            end
          end

          context "and the schedule includes upcoming oc that closes after ends_at" do
            let!(:oc) { upcoming_closes_on_ends_at_oc }

            it "creates a new proxy order for that oc" do
              syncer.sync!

              expect{ subscription.save! }.to change(ProxyOrder, :count).from(0).to(1)
              expect(subscription.reload.proxy_orders.map(&:order_cycle)).to include oc
            end
          end

          context "and the schedule includes upcoming oc that closes after ends_at" do
            let!(:oc) { upcoming_closes_after_ends_at_oc }

            it "does not create a new proxy order for that oc" do
              expect{ subscription.save! }.to_not change(ProxyOrder, :count).from(0)
              expect(order_cycles).to_not include oc
            end
          end
        end

        context "when the subscription is persisted" do
          before { expect(subscription.save!).to be true }

          context "when a proxy order exists" do
            let!(:proxy_order) { create(:proxy_order, subscription: subscription, order_cycle: oc) }

            context "for an oc included in the relevant schedule" do
              context "and the proxy order has already been placed" do
                before { proxy_order.update(placed_at: 5.minutes.ago) }

                context "the oc is closed (ie. closed before opens_at)" do
                  let(:oc) { closed_oc }
                  it "keeps the proxy order" do
                    expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                    expect(proxy_orders).to include proxy_order
                  end
                end

                context "and the schedule includes an open oc that closes before begins_at" do
                  let(:oc) { open_oc_closes_before_begins_at_oc }
                  it "keeps the proxy order" do
                    expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                    expect(proxy_orders).to include proxy_order
                  end
                end

                context "and the oc is open and closes between begins_at and ends_at" do
                  let(:oc) { open_oc }
                  it "keeps the proxy order" do
                    expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                    expect(proxy_orders).to include proxy_order
                  end
                end

                context "and the oc is upcoming and closes before begins_at" do
                  let(:oc) { upcoming_closes_before_begins_at_oc }
                  it "keeps the proxy order" do
                    expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                    expect(proxy_orders).to include proxy_order
                  end
                end

                context "and the oc is upcoming and closes on begins_at" do
                  let(:oc) { upcoming_closes_on_begins_at_oc }
                  it "keeps the proxy order" do
                    expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                    expect(proxy_orders).to include proxy_order
                  end
                end

                context "and the oc is upcoming and closes on ends_at" do
                  let(:oc) { upcoming_closes_on_ends_at_oc }
                  it "keeps the proxy order" do
                    expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                    expect(proxy_orders).to include proxy_order
                  end
                end

                context "and the oc is upcoming and closes after ends_at" do
                  let(:oc) { upcoming_closes_after_ends_at_oc }
                  it "keeps the proxy order" do
                    expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                    expect(proxy_orders).to include proxy_order
                  end
                end
              end

              context "and the proxy order has not already been placed" do
                context "the oc is closed (ie. closed before opens_at)" do
                  let(:oc) { closed_oc }

                  it "removes the proxy order" do
                    expect{ syncer.sync! }.to change(ProxyOrder, :count).from(1).to(0)
                    expect(proxy_orders).to_not include proxy_order
                  end
                end

                context "and the schedule includes an open oc that closes before begins_at" do
                  let(:oc) { open_oc_closes_before_begins_at_oc }

                  it "removes the proxy order" do
                    expect{ syncer.sync! }.to change(ProxyOrder, :count).from(1).to(0)
                    expect(proxy_orders).to_not include proxy_order
                  end
                end

                context 'and the proxy orders are already synced' do
                  let(:subscription) do
                    build(
                      :subscription,
                      begins_at: now + 1.minute,
                      ends_at: now + 2.minutes,
                      schedule: schedule
                    )
                  end

                  before { syncer.sync! }

                  context "and the oc is open and closes between begins_at and ends_at" do
                    let(:oc) { open_oc }

                    it "keeps the proxy order" do
                      expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                      expect(proxy_orders).to include proxy_order
                    end
                  end

                  context "and the oc is upcoming and closes on begins_at" do
                    let(:oc) { upcoming_closes_on_begins_at_oc }

                    it "keeps the proxy order" do
                      expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                      expect(proxy_orders).to include proxy_order
                    end
                  end

                  context "and the oc is upcoming and closes on ends_at" do
                    let(:oc) { upcoming_closes_on_ends_at_oc }

                    it "keeps the proxy order" do
                      expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                      expect(proxy_orders).to include proxy_order
                    end
                  end
                end

                context "and the oc is upcoming and closes before begins_at" do
                  let(:oc) { upcoming_closes_before_begins_at_oc }

                  it "removes the proxy order" do
                    expect{ syncer.sync! }.to change(ProxyOrder, :count).from(1).to(0)
                    expect(proxy_orders).to_not include proxy_order
                  end
                end

                context "and the oc is upcoming and closes after ends_at" do
                  let(:oc) { upcoming_closes_after_ends_at_oc }

                  it "removes the proxy order" do
                    expect{ syncer.sync! }.to change(ProxyOrder, :count).from(1).to(0)
                    expect(proxy_orders).to_not include proxy_order
                  end
                end
              end
            end

            context "for an oc not included in the relevant schedule" do
              let!(:proxy_order) {
                create(:proxy_order, subscription: subscription, order_cycle: open_oc)
              }
              before do
                open_oc.schedule_ids = []
                expect(open_oc.save!).to be true
              end

              context "and the proxy order has already been placed" do
                before { proxy_order.update(placed_at: 5.minutes.ago) }

                context "the oc is closed (ie. closed before opens_at)" do
                  let(:oc) { closed_oc }
                  it "keeps the proxy order" do
                    expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                    expect(proxy_orders).to include proxy_order
                  end
                end

                context "and the schedule includes an open oc that closes before begins_at" do
                  let(:oc) { open_oc_closes_before_begins_at_oc }
                  it "keeps the proxy order" do
                    expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                    expect(proxy_orders).to include proxy_order
                  end
                end

                context "and the oc is open and closes between begins_at and ends_at" do
                  let(:oc) { open_oc }
                  it "keeps the proxy order" do
                    expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                    expect(proxy_orders).to include proxy_order
                  end
                end

                context "and the oc is upcoming and closes before begins_at" do
                  let(:oc) { upcoming_closes_before_begins_at_oc }
                  it "keeps the proxy order" do
                    expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                    expect(proxy_orders).to include proxy_order
                  end
                end

                context "and the oc is upcoming and closes on begins_at" do
                  let(:oc) { upcoming_closes_on_begins_at_oc }
                  it "keeps the proxy order" do
                    expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                    expect(proxy_orders).to include proxy_order
                  end
                end

                context "and the oc is upcoming and closes on ends_at" do
                  let(:oc) { upcoming_closes_on_ends_at_oc }
                  it "keeps the proxy order" do
                    expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                    expect(proxy_orders).to include proxy_order
                  end
                end

                context "and the oc is upcoming and closes after ends_at" do
                  let(:oc) { upcoming_closes_after_ends_at_oc }
                  it "keeps the proxy order" do
                    expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(1)
                    expect(proxy_orders).to include proxy_order
                  end
                end
              end

              context "and the proxy order has not already been placed" do
                # This shouldn't really happen, but it is possible
                context "the oc is closed (ie. closed before opens_at)" do
                  let(:oc) { closed_oc }
                  it "removes the proxy order" do
                    expect{ syncer.sync! }.to change(ProxyOrder, :count).from(1).to(0)
                    expect(proxy_orders).to_not include proxy_order
                  end
                end

                # This shouldn't really happen, but it is possible
                context "and the oc is open and closes between begins_at and ends_at" do
                  let(:oc) { open_oc }
                  it "removes the proxy order" do
                    expect{ syncer.sync! }.to change(ProxyOrder, :count).from(1).to(0)
                    expect(proxy_orders).to_not include proxy_order
                  end
                end

                context "and the oc is upcoming and closes before begins_at" do
                  let(:oc) { upcoming_closes_before_begins_at_oc }
                  it "removes the proxy order" do
                    expect{ syncer.sync! }.to change(ProxyOrder, :count).from(1).to(0)
                    expect(proxy_orders).to_not include proxy_order
                  end
                end

                context "and the oc is upcoming and closes on begins_at" do
                  let(:oc) { upcoming_closes_on_begins_at_oc }
                  it "removes the proxy order" do
                    expect{ syncer.sync! }.to change(ProxyOrder, :count).from(1).to(0)
                    expect(proxy_orders).to_not include proxy_order
                  end
                end

                context "and the oc is upcoming and closes on ends_at" do
                  let(:oc) { upcoming_closes_on_ends_at_oc }
                  it "removes the proxy order" do
                    expect{ syncer.sync! }.to change(ProxyOrder, :count).from(1).to(0)
                    expect(proxy_orders).to_not include proxy_order
                  end
                end

                context "and the oc is upcoming and closes after ends_at" do
                  let(:oc) { upcoming_closes_after_ends_at_oc }
                  it "removes the proxy order" do
                    expect{ syncer.sync! }.to change(ProxyOrder, :count).from(1).to(0)
                    expect(proxy_orders).to_not include proxy_order
                  end
                end
              end
            end
          end

          context "when a proxy order does not exist" do
            let(:schedule) { create(:schedule, order_cycles: [oc]) }
            let(:subscription) do
              create(
                :subscription,
                begins_at: now + 1.minute,
                ends_at: now + 2.minutes,
                schedule: schedule
              )
            end
            let(:syncer) { ProxyOrderSyncer.new(subscription) }

            context "and the schedule includes a closed oc (ie. closed before opens_at)" do
              let!(:oc) { closed_oc }

              it "does not create a new proxy order for that oc" do
                expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(0)
                expect(order_cycles).to_not include oc
              end
            end

            context "and the schedule includes an open oc that closes before begins_at" do
              let(:oc) { open_oc_closes_before_begins_at_oc }

              it "does not create a new proxy order for that oc" do
                expect{ subscription.save! }.to_not change(ProxyOrder, :count).from(0)
                expect(order_cycles).to_not include oc
              end
            end

            context "and the schedule has an open oc that closes between begins_at and ends_at" do
              let!(:oc) { open_oc }

              it "creates a new proxy order for that oc" do
                expect{ syncer.sync! }.to change(ProxyOrder, :count).from(0).to(1)
                expect(subscription.reload.proxy_orders.map(&:order_cycle)).to include oc
              end
            end

            context "and the schedule includes upcoming oc that closes before begins_at" do
              let!(:oc) { upcoming_closes_before_begins_at_oc }

              it "does not create a new proxy order for that oc" do
                expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(0)
                expect(order_cycles).to_not include oc
              end
            end

            context "and the schedule includes upcoming oc that closes on begins_at" do
              let!(:oc) { upcoming_closes_on_begins_at_oc }

              it "creates a new proxy order for that oc" do
                expect{ syncer.sync! }.to change(ProxyOrder, :count).from(0).to(1)
                expect(subscription.reload.proxy_orders.map(&:order_cycle)).to include oc
              end
            end

            context "and the schedule includes upcoming oc that closes on ends_at" do
              let!(:oc) { upcoming_closes_on_ends_at_oc }

              it "creates a new proxy order for that oc" do
                expect{ syncer.sync! }.to change(ProxyOrder, :count).from(0).to(1)
                expect(subscription.reload.proxy_orders.map(&:order_cycle)).to include oc
              end
            end

            context "and the schedule includes upcoming oc that closes after ends_at" do
              let!(:oc) { upcoming_closes_after_ends_at_oc }

              it "does not create a new proxy order for that oc" do
                expect{ syncer.sync! }.to_not change(ProxyOrder, :count).from(0)
                expect(order_cycles).to_not include oc
              end
            end
          end
        end
      end
    end
  end
end
