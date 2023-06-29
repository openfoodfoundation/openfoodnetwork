# frozen_string_literal: true

require "spec_helper"

require 'open_food_network/order_cycle_form_applicator'

module OpenFoodNetwork
  describe OrderCycleFormApplicator do
    let!(:user) { create(:user) }

    context "unit specs" do
      it "creates new exchanges for incoming_exchanges" do
        coordinator_id = 123
        supplier_id = 456

        incoming_exchange = { enterprise_id: supplier_id, incoming: true,
                              variants: { '1' => true, '2' => false, '3' => true },
                              enterprise_fee_ids: [1, 2],
                              receival_instructions: 'receival instructions' }

        oc = double(:order_cycle, coordinator_id: coordinator_id, exchanges: [],
                                  incoming_exchanges: [incoming_exchange], outgoing_exchanges: [])

        applicator = OrderCycleFormApplicator.new(oc, user)

        expect(applicator).to receive(:incoming_exchange_variant_ids)
          .with(incoming_exchange).and_return([1, 3])
        expect(applicator).to receive(:exchange_exists?).with(supplier_id, coordinator_id,
                                                              true).and_return(false)
        expect(applicator).to receive(:add_exchange)
          .with(supplier_id, coordinator_id, true,
                variant_ids: [1, 3],
                enterprise_fee_ids: [1, 2],
                receival_instructions: 'receival instructions')
        expect(applicator).to receive(:destroy_untouched_exchanges)

        applicator.go!
      end

      it "creates new exchanges for outgoing_exchanges" do
        coordinator_id = 123
        distributor_id = 456

        outgoing_exchange = { enterprise_id: distributor_id, incoming: false,
                              variants: { '1' => true, '2' => false, '3' => true },
                              enterprise_fee_ids: [1, 2], pickup_time: 'pickup time',
                              pickup_instructions: 'pickup instructions', tag_list: 'wholesale' }

        oc = double(:order_cycle, coordinator_id: coordinator_id, exchanges: [],
                                  incoming_exchanges: [], outgoing_exchanges: [outgoing_exchange])

        applicator = OrderCycleFormApplicator.new(oc, user)

        expect(applicator).to receive(:outgoing_exchange_variant_ids)
          .with(outgoing_exchange).and_return([1, 3])
        expect(applicator).to receive(:exchange_exists?).with(coordinator_id, distributor_id,
                                                              false).and_return(false)
        expect(applicator).to receive(:add_exchange)
          .with(coordinator_id, distributor_id, false,
                variant_ids: [1, 3],
                enterprise_fee_ids: [1, 2],
                pickup_time: 'pickup time',
                pickup_instructions: 'pickup instructions',
                tag_list: 'wholesale')
        expect(applicator).to receive(:destroy_untouched_exchanges)

        applicator.go!
      end

      it "updates existing exchanges for incoming_exchanges" do
        coordinator_id = 123
        supplier_id = 456

        incoming_exchange = { enterprise_id: supplier_id, incoming: true,
                              variants: { '1' => true, '2' => false, '3' => true },
                              enterprise_fee_ids: [1, 2],
                              receival_instructions: 'receival instructions' }

        oc = double(:order_cycle,
                    coordinator_id: coordinator_id,
                    exchanges: [double(:exchange, sender_id: supplier_id,
                                                  receiver_id: coordinator_id, incoming: true)],
                    incoming_exchanges: [incoming_exchange],
                    outgoing_exchanges: [])

        applicator = OrderCycleFormApplicator.new(oc, user)

        expect(applicator).to receive(:incoming_exchange_variant_ids)
          .with(incoming_exchange).and_return([1, 3])
        expect(applicator).to receive(:exchange_exists?).with(supplier_id, coordinator_id,
                                                              true).and_return(true)
        expect(applicator).to receive(:update_exchange)
          .with(supplier_id, coordinator_id, true,
                variant_ids: [1, 3],
                enterprise_fee_ids: [1, 2],
                receival_instructions: 'receival instructions')
        expect(applicator).to receive(:destroy_untouched_exchanges)

        applicator.go!
      end

      it "updates existing exchanges for outgoing_exchanges" do
        coordinator_id = 123
        distributor_id = 456

        outgoing_exchange = { enterprise_id: distributor_id, incoming: false,
                              variants: { '1' => true, '2' => false, '3' => true },
                              enterprise_fee_ids: [1, 2], pickup_time: 'pickup time',
                              pickup_instructions: 'pickup instructions', tag_list: 'wholesale' }

        oc = double(:order_cycle,
                    coordinator_id: coordinator_id,
                    exchanges: [double(:exchange, sender_id: coordinator_id,
                                                  receiver_id: distributor_id, incoming: false)],
                    incoming_exchanges: [],
                    outgoing_exchanges: [outgoing_exchange])

        applicator = OrderCycleFormApplicator.new(oc, user)

        expect(applicator).to receive(:outgoing_exchange_variant_ids)
          .with(outgoing_exchange).and_return([1, 3])
        expect(applicator).to receive(:exchange_exists?).with(coordinator_id, distributor_id,
                                                              false).and_return(true)
        expect(applicator).to receive(:update_exchange)
          .with(coordinator_id, distributor_id, false,
                variant_ids: [1, 3],
                enterprise_fee_ids: [1, 2],
                pickup_time: 'pickup time',
                pickup_instructions: 'pickup instructions',
                tag_list: 'wholesale')
        expect(applicator).to receive(:destroy_untouched_exchanges)

        applicator.go!
      end

      describe "removing exchanges that are no longer present" do
        it "destroys untouched exchanges" do
          coordinator_id = 123
          supplier_id = 456
          exchange = double(:exchange, id: 1, sender_id: supplier_id, receiver_id: coordinator_id,
                                       incoming: true)

          oc = double(:order_cycle,
                      coordinator_id: coordinator_id,
                      exchanges: [exchange],
                      incoming_exchanges: [],
                      outgoing_exchanges: [])

          applicator = OrderCycleFormApplicator.new(oc, user)

          expect(applicator).to receive(:destroy_untouched_exchanges)

          applicator.go!
          expect(applicator.send(:untouched_exchanges)).to eq([exchange])
        end

        it "compares exchanges by id only" do
          e1 = double(:exchange1, id: 1, foo: 1)
          e2 = double(:exchange2, id: 1, foo: 2)
          oc = double(:order_cycle, exchanges: [e1])

          applicator = OrderCycleFormApplicator.new(oc, user)
          applicator.instance_eval do
            @touched_exchanges = [e2]
          end

          expect(applicator.send(:untouched_exchanges)).to eq([])
        end

        context "as a manager of the coordinator" do
          let(:applicator) { OrderCycleFormApplicator.new(nil, user) }
          before { allow(applicator).to receive(:manages_coordinator?) { true } }

          it "destroys exchanges" do
            exchanges = [double(:exchange), double(:exchange)]
            expect(applicator).to receive(:untouched_exchanges) { exchanges }
            exchanges.each { |ex| expect(ex).to receive(:destroy) }

            applicator.send(:destroy_untouched_exchanges)
          end
        end

        context "as a non-manager of the coordinator" do
          let(:applicator) { OrderCycleFormApplicator.new(nil, user) }
          before { allow(applicator).to receive(:manages_coordinator?) { false } }

          it "does not destroy any exchanges" do
            expect(applicator).to_not receive(:with_permission)
            applicator.send(:destroy_untouched_exchanges)
          end
        end
      end

      describe "updating the list of variants for a given outgoing exchange" do
        let!(:v1) { create(:variant) } # Not Existing + Request Add + Editable + Incoming
        let!(:v2) { create(:variant) } # Not Existing + Request Add + Not Editable + Incoming
        let!(:v3) { create(:variant) } # Existing + Request Add + Editable + Incoming
        let!(:v4) { create(:variant) } # Existing + Not mentioned + Editable + Incoming
        let!(:v5) { create(:variant) } # Existing + Request Remove + Editable + Incoming
        let!(:v6) { create(:variant) } # Existing + Request Remove + Not Editable + Incoming
        let!(:v7) { create(:variant) } # Existing + Request Add + Not Editable + Not Incoming
        let!(:v8) { create(:variant) } # Existing + Request Add + Editable + Not Incoming
        let!(:v9) { create(:variant) } # Not Existing + Request Add + Editable + Not Incoming
        let!(:exchange) {
          create(:exchange, incoming: false,
                            variant_ids: [v3.id, v4.id, v5.id, v6.id, v7.id, v8.id])
        }
        let!(:oc) { exchange.order_cycle }
        let!(:enterprise) { exchange.receiver }
        let!(:coordinator) { oc.coordinator }
        let!(:applicator) { OrderCycleFormApplicator.new(oc, user) }
        let(:ids) do
          applicator.send(:outgoing_exchange_variant_ids,
                          enterprise_id: enterprise.id,
                          variants: {
                            v1.id.to_s => true,
                            v2.id.to_s => true,
                            v3.id.to_s => true,
                            v5.id.to_s => false,
                            v6.id.to_s => false,
                            v7.id.to_s => true,
                            v8.id.to_s => true,
                            v9.id.to_s => true
                          })
        end

        before do
          allow(applicator).to receive(:incoming_variant_ids) {
                                 [v1.id, v2.id, v3.id, v4.id, v5.id, v6.id]
                               }
          allow(applicator).to receive(:editable_variant_ids_for_outgoing_exchange_between) {
                                 [v1.id, v3.id, v4.id, v5.id, v8.id, v9.id]
                               }
        end

        it "updates the list of variants for the exchange" do
          # Adds variants that are editable
          expect(ids).to include v1.id

          # Does not add variants that are not editable
          expect(ids).to_not include v2.id

          # Keeps existing variants, when they are explicitly mentioned in the request
          expect(ids).to include v3.id

          # Removes existing variants that are editable, when they are not mentioned in the request
          expect(ids).to_not include v4.id

          # Removes existing variants that are editable, when the request explicitly removes them
          expect(ids).to_not include v5.id

          # Keeps existing variants that are not editable
          expect(ids).to include v6.id

          # Removes existing variants that are not in an incoming exchange,
          # regardless of whether they are not editable
          expect(ids).to_not include v7.id, v8.id

          # Does not add variants that are not in an incoming exchange
          expect(ids).to_not include v9.id
        end
      end

      describe "updating the list of variants for a given incoming exchange" do
        let!(:v1) { create(:variant) } # Not Existing + Request Add + Editable
        let!(:v2) { create(:variant) } # Not Existing + Request Add + Not Editable
        let!(:v3) { create(:variant) } # Existing + Request Add + Editable
        let!(:v4) { create(:variant) } # Existing + Request Remove + Not Editable
        let!(:v5) { create(:variant) } # Existing + Request Remove + Editable
        let!(:v6) { create(:variant) } # Existing + Request Remove + Not Editable
        let!(:v7) { create(:variant) } # Existing + Not mentioned + Editable
        let!(:exchange) {
          create(:exchange, incoming: true, variant_ids: [v3.id, v4.id, v5.id, v6.id, v7.id])
        }
        let!(:oc) { exchange.order_cycle }
        let!(:enterprise) { exchange.sender }
        let!(:coordinator) { oc.coordinator }
        let!(:applicator) { OrderCycleFormApplicator.new(oc, user) }
        let(:ids) do
          applicator.send(:incoming_exchange_variant_ids,
                          enterprise_id: enterprise.id,
                          variants: {
                            v1.id.to_s => true,
                            v2.id.to_s => true,
                            v3.id.to_s => true,
                            v4.id.to_s => false,
                            v5.id.to_s => false,
                            v6.id.to_s => false
                          })
        end

        before do
          allow(applicator).to receive(:editable_variant_ids_for_incoming_exchange_between) {
                                 [v1.id, v3.id, v5.id, v7.id]
                               }
        end

        it "updates the list of variants for the exchange" do
          # Adds variants that are editable
          expect(ids).to include v1.id

          # Does not add variants that are not editable
          expect(ids).to_not include v2.id

          # Keeps existing variants, if they are editable and requested
          expect(ids).to include v3.id

          # Keeps existing variants if they are non-editable, regardless of request
          expect(ids).to include v4.id

          # Removes existing variants that are editable, when the request explicitly removes them
          expect(ids).to_not include v5.id

          # Keeps existing variants that are not editable
          expect(ids).to include v6.id

          # Removes existing variants that are editable, when they are not mentioned in the request
          expect(ids).to_not include v7.id
        end
      end

      describe "filtering exchanges for permission" do
        describe "checking permission on a single exchange" do
          it "returns true when it has permission" do
            e = double(:enterprise)
            ex = double(:exchange, participant: e)

            applicator = OrderCycleFormApplicator.new(nil, user)
            allow(applicator).to receive(:permitted_enterprises) { [e] }

            expect(applicator.send(:permission_for, ex)).to be true
          end

          it "returns false otherwise" do
            e = double(:enterprise)
            ex = double(:exchange, participant: e)

            applicator = OrderCycleFormApplicator.new(nil, user)
            allow(applicator).to receive(:permitted_enterprises) { [] }

            expect(applicator.send(:permission_for, ex)).to be false
          end
        end
      end
    end

    context "integration specs" do
      before(:all) do
        require 'spec_helper'
      end

      it "checks whether exchanges exist" do
        oc = FactoryBot.create(:simple_order_cycle)
        exchange = FactoryBot.create(:exchange, order_cycle: oc)
        applicator = OrderCycleFormApplicator.new(oc, user)

        expect(applicator.send(:exchange_exists?, exchange.sender_id, exchange.receiver_id,
                               exchange.incoming)).to be true
        expect(applicator.send(:exchange_exists?, exchange.sender_id, exchange.receiver_id,
                               !exchange.incoming)).to be false
        expect(applicator.send(:exchange_exists?, exchange.receiver_id, exchange.sender_id,
                               exchange.incoming)).to be false
        expect(applicator.send(:exchange_exists?, exchange.sender_id, 999_999,
                               exchange.incoming)).to be false
        expect(applicator.send(:exchange_exists?, 999_999, exchange.receiver_id,
                               exchange.incoming)).to be false
        expect(applicator.send(:exchange_exists?, 999_999, 888_888, exchange.incoming)).to be false
      end

      describe "adding exchanges" do
        let!(:sender) { create(:enterprise) }
        let!(:receiver) { create(:enterprise) }
        let!(:oc) { create(:simple_order_cycle) }
        let!(:applicator) { OrderCycleFormApplicator.new(oc, user) }
        let!(:incoming) { true }
        let!(:variant1) { create(:variant) }
        let!(:variant2) { create(:variant) }
        let!(:enterprise_fee1) { create(:enterprise_fee) }
        let!(:enterprise_fee2) { create(:enterprise_fee) }

        context "as a manager of the coorindator" do
          before do
            allow(applicator).to receive(:manages_coordinator?) { true }
            applicator.send(:touched_exchanges=, [])
            applicator.send(:add_exchange, sender.id, receiver.id, incoming,
                            variant_ids: [variant1.id, variant2.id],
                            enterprise_fee_ids: [enterprise_fee1.id, enterprise_fee2.id])
          end

          it "adds new exchanges" do
            exchange = Exchange.last
            expect(exchange.sender).to eq sender
            expect(exchange.receiver).to eq receiver
            expect(exchange.incoming).to eq incoming
            expect(exchange.variants).to match_array [variant1, variant2]
            expect(exchange.enterprise_fees).to match_array [enterprise_fee1, enterprise_fee2]

            expect(applicator.send(:touched_exchanges)).to eq([exchange])
          end
        end

        context "as a user which does not manage the coorindator" do
          before do
            allow(applicator).to receive(:manages_coordinator?) { false }
            applicator.send(:add_exchange, sender.id, receiver.id, incoming,
                            variant_ids: [variant1.id, variant2.id],
                            enterprise_fee_ids: [enterprise_fee1.id, enterprise_fee2.id])
          end

          it "does not add new exchanges" do
            expect(Exchange.last).to be_nil
          end
        end
      end

      describe "updating exchanges" do
        let!(:sender) { create(:enterprise) }
        let!(:receiver) { create(:enterprise) }
        let!(:oc) { create(:simple_order_cycle) }
        let!(:applicator) { OrderCycleFormApplicator.new(oc, user) }
        let!(:incoming) { true }
        let!(:variant1) { create(:variant) }
        let!(:variant2) { create(:variant) }
        let!(:variant3) { create(:variant) }
        let!(:enterprise_fee1) { create(:enterprise_fee) }
        let!(:enterprise_fee2) { create(:enterprise_fee) }
        let!(:enterprise_fee3) { create(:enterprise_fee) }

        let!(:exchange) {
          create(:exchange, order_cycle: oc, sender: sender, receiver: receiver, incoming: incoming,
                            variant_ids: [variant1.id, variant2.id],
                            enterprise_fee_ids: [enterprise_fee1.id, enterprise_fee2.id])
        }

        context "as a manager of the coorindator" do
          before do
            allow(applicator).to receive(:manages_coordinator?) { true }
            allow(applicator).to receive(:manager_for) { false }
            allow(applicator).to receive(:permission_for) { true }
            applicator.send(:touched_exchanges=, [])
            applicator.send(:update_exchange, sender.id, receiver.id, incoming,
                            variant_ids: [variant1.id, variant3.id],
                            enterprise_fee_ids: [enterprise_fee2.id, enterprise_fee3.id],
                            pickup_time: 'New Pickup Time',
                            pickup_instructions: 'New Pickup Instructions',
                            tag_list: 'wholesale')
          end

          it "updates the variants, enterprise fees tags, and pickup information of the exchange" do
            exchange.reload
            expect(exchange.variants).to match_array [variant1, variant3]
            expect(exchange.enterprise_fees).to match_array [enterprise_fee2, enterprise_fee3]
            expect(exchange.pickup_time).to eq 'New Pickup Time'
            expect(exchange.pickup_instructions).to eq 'New Pickup Instructions'
            expect(exchange.tag_list).to eq ['wholesale']
            expect(applicator.send(:touched_exchanges)).to eq [exchange]
          end
        end

        context "as a manager of the participating enterprise" do
          before do
            allow(applicator).to receive(:manages_coordinator?) { false }
            allow(applicator).to receive(:manager_for) { true }
            allow(applicator).to receive(:permission_for) { true }
            applicator.send(:touched_exchanges=, [])
            applicator.send(:update_exchange, sender.id, receiver.id, incoming,
                            variant_ids: [variant1.id, variant3.id],
                            enterprise_fee_ids: [enterprise_fee2.id, enterprise_fee3.id],
                            pickup_time: 'New Pickup Time',
                            pickup_instructions: 'New Pickup Instructions',
                            tag_list: 'wholesale')
          end

          it "updates the variants, enterprise fees, tags and pickup information of the exchange" do
            exchange.reload
            expect(exchange.variants).to match_array [variant1, variant3]
            expect(exchange.enterprise_fees).to match_array [enterprise_fee2, enterprise_fee3]
            expect(exchange.pickup_time).to eq 'New Pickup Time'
            expect(exchange.pickup_instructions).to eq 'New Pickup Instructions'
            expect(exchange.tag_list).to eq ['wholesale']
            expect(applicator.send(:touched_exchanges)).to eq [exchange]
          end
        end

        context "where the participating enterprise is permitted for the user" do
          before do
            allow(applicator).to receive(:manages_coordinator?) { false }
            allow(applicator).to receive(:manager_for) { false }
            allow(applicator).to receive(:permission_for) { true }
            applicator.send(:touched_exchanges=, [])
            applicator.send(:update_exchange, sender.id, receiver.id, incoming,
                            variant_ids: [variant1.id, variant3.id],
                            enterprise_fee_ids: [enterprise_fee2.id, enterprise_fee3.id],
                            pickup_time: 'New Pickup Time',
                            pickup_instructions: 'New Pickup Instructions',
                            tag_list: 'wholesale')
          end

          it "updates the variants in the exchange, but not the fees, tags or pickup information" do
            exchange.reload
            expect(exchange.variants).to match_array [variant1, variant3]
            expect(exchange.enterprise_fees).to match_array [enterprise_fee1, enterprise_fee2]
            expect(exchange.pickup_time).to_not eq 'New Pickup Time'
            expect(exchange.pickup_instructions).to_not eq 'New Pickup Instructions'
            expect(exchange.tag_list).to eq []
            expect(applicator.send(:touched_exchanges)).to eq [exchange]
          end
        end
      end

      it "does not add exchanges it is not permitted to touch" do
        sender = FactoryBot.create(:enterprise)
        receiver = FactoryBot.create(:enterprise)
        oc = FactoryBot.create(:simple_order_cycle)
        applicator = OrderCycleFormApplicator.new(oc, user)
        incoming = true

        expect do
          applicator.send(:touched_exchanges=, [])
          applicator.send(:add_exchange, sender.id, receiver.id, incoming)
        end.to change(Exchange, :count).by(0)
      end

      it "does not update exchanges it is not permitted to touch" do
        sender = FactoryBot.create(:enterprise)
        receiver = FactoryBot.create(:enterprise)
        oc = FactoryBot.create(:simple_order_cycle)
        applicator = OrderCycleFormApplicator.new(oc, user)
        incoming = true
        exchange = FactoryBot.create(:exchange, order_cycle: oc, sender: sender,
                                                receiver: receiver, incoming: incoming)
        variant1 = FactoryBot.create(:variant)

        applicator.send(:touched_exchanges=, [])
        applicator.send(:update_exchange, sender.id, receiver.id, incoming,
                        variant_ids: [variant1.id])

        expect(exchange.variants).not_to eq([variant1])
      end
    end
  end
end
