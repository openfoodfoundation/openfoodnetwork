require 'open_food_network/order_cycle_form_applicator'

module OpenFoodNetwork
  describe OrderCycleFormApplicator do
    include AuthenticationWorkflow

    let!(:user) { create_enterprise_user }

    context "unit specs" do
      it "creates new exchanges for incoming_exchanges" do
        coordinator_id = 123
        supplier_id = 456

        incoming_exchange = {:enterprise_id => supplier_id, :incoming => true, :variants => {'1' => true, '2' => false, '3' => true}, :enterprise_fee_ids => [1, 2], :receival_instructions => 'receival instructions'}

        oc = double(:order_cycle, :coordinator_id => coordinator_id, :exchanges => [], :incoming_exchanges => [incoming_exchange], :outgoing_exchanges => [])

        applicator = OrderCycleFormApplicator.new(oc, user)

        applicator.should_receive(:incoming_exchange_variant_ids).with(incoming_exchange).and_return([1, 3])
        applicator.should_receive(:exchange_exists?).with(supplier_id, coordinator_id, true).and_return(false)
        applicator.should_receive(:add_exchange).with(supplier_id, coordinator_id, true, {:variant_ids => [1, 3], :enterprise_fee_ids => [1, 2], :receival_instructions => 'receival instructions'})
        applicator.should_receive(:destroy_untouched_exchanges)

        applicator.go!
      end

      it "creates new exchanges for outgoing_exchanges" do
        coordinator_id = 123
        distributor_id = 456

        outgoing_exchange = {:enterprise_id => distributor_id, :incoming => false, :variants => {'1' => true, '2' => false, '3' => true}, :enterprise_fee_ids => [1, 2], :pickup_time => 'pickup time', :pickup_instructions => 'pickup instructions'}

        oc = double(:order_cycle, :coordinator_id => coordinator_id, :exchanges => [], :incoming_exchanges => [], :outgoing_exchanges => [outgoing_exchange])

        applicator = OrderCycleFormApplicator.new(oc, user)

        applicator.should_receive(:outgoing_exchange_variant_ids).with(outgoing_exchange).and_return([1, 3])
        applicator.should_receive(:exchange_exists?).with(coordinator_id, distributor_id, false).and_return(false)
        applicator.should_receive(:add_exchange).with(coordinator_id, distributor_id, false, {:variant_ids => [1, 3], :enterprise_fee_ids => [1, 2], :pickup_time => 'pickup time', :pickup_instructions => 'pickup instructions'})
        applicator.should_receive(:destroy_untouched_exchanges)

        applicator.go!
      end

      it "updates existing exchanges for incoming_exchanges" do
        coordinator_id = 123
        supplier_id = 456

        incoming_exchange = {:enterprise_id => supplier_id, :incoming => true, :variants => {'1' => true, '2' => false, '3' => true}, :enterprise_fee_ids => [1, 2], :receival_instructions => 'receival instructions'}

        oc = double(:order_cycle,
                    :coordinator_id => coordinator_id,
                    :exchanges => [double(:exchange, :sender_id => supplier_id, :receiver_id => coordinator_id, :incoming => true)],
                    :incoming_exchanges => [incoming_exchange],
                    :outgoing_exchanges => [])

        applicator = OrderCycleFormApplicator.new(oc, user)

        applicator.should_receive(:incoming_exchange_variant_ids).with(incoming_exchange).and_return([1, 3])
        applicator.should_receive(:exchange_exists?).with(supplier_id, coordinator_id, true).and_return(true)
        applicator.should_receive(:update_exchange).with(supplier_id, coordinator_id, true, {:variant_ids => [1, 3], :enterprise_fee_ids => [1, 2], :receival_instructions => 'receival instructions'})
        applicator.should_receive(:destroy_untouched_exchanges)

        applicator.go!
      end

      it "updates existing exchanges for outgoing_exchanges" do
        coordinator_id = 123
        distributor_id = 456

        outgoing_exchange = {:enterprise_id => distributor_id, :incoming => false, :variants => {'1' => true, '2' => false, '3' => true}, :enterprise_fee_ids => [1, 2], :pickup_time => 'pickup time', :pickup_instructions => 'pickup instructions'}

        oc = double(:order_cycle,
                    :coordinator_id => coordinator_id,
                    :exchanges => [double(:exchange, :sender_id => coordinator_id, :receiver_id => distributor_id, :incoming => false)],
                    :incoming_exchanges => [],
                    :outgoing_exchanges => [outgoing_exchange])

        applicator = OrderCycleFormApplicator.new(oc, user)

        applicator.should_receive(:outgoing_exchange_variant_ids).with(outgoing_exchange).and_return([1, 3])
        applicator.should_receive(:exchange_exists?).with(coordinator_id, distributor_id, false).and_return(true)
        applicator.should_receive(:update_exchange).with(coordinator_id, distributor_id, false, {:variant_ids => [1, 3], :enterprise_fee_ids => [1, 2], :pickup_time => 'pickup time', :pickup_instructions => 'pickup instructions'})
        applicator.should_receive(:destroy_untouched_exchanges)

        applicator.go!
      end

      describe "removing exchanges that are no longer present" do
        it "destroys untouched exchanges" do
          coordinator_id = 123
          supplier_id = 456
          exchange = double(:exchange, :id => 1, :sender_id => supplier_id, :receiver_id => coordinator_id, :incoming => true)

          oc = double(:order_cycle,
                      :coordinator_id => coordinator_id,
                      :exchanges => [exchange],
                      :incoming_exchanges => [],
                      :outgoing_exchanges => [])

          applicator = OrderCycleFormApplicator.new(oc, user)

          applicator.should_receive(:destroy_untouched_exchanges)

          applicator.go!
          applicator.send(:untouched_exchanges).should == [exchange]
        end

        it "compares exchanges by id only" do
          e1 = double(:exchange1, id: 1, foo: 1)
          e2 = double(:exchange2, id: 1, foo: 2)
          oc = double(:order_cycle, :exchanges => [e1])

          applicator = OrderCycleFormApplicator.new(oc, user)
          applicator.instance_eval do
            @touched_exchanges = [e2]
          end

          applicator.send(:untouched_exchanges).should == []
        end

        context "as a manager of the coordinator" do
          let(:applicator) { OrderCycleFormApplicator.new(nil, user) }
          before { applicator.stub(:manages_coordinator?) { true } }

          it "destroys exchanges" do
            exchanges = [double(:exchange), double(:exchange)]
            expect(applicator).to receive(:untouched_exchanges) { exchanges }
            exchanges.each { |ex| expect(ex).to receive(:destroy) }

            applicator.send(:destroy_untouched_exchanges)
          end
        end

        context "as a non-manager of the coordinator" do
          let(:applicator) { OrderCycleFormApplicator.new(nil, user) }
          before { applicator.stub(:manages_coordinator?) { false } }

          it "does not destroy any exchanges" do
            expect(applicator).to_not receive(:with_permission)
            applicator.send(:destroy_untouched_exchanges)
          end
        end
      end

      describe "finding alterable exchange variants" do
        let(:coordinator_mock) { double(:enterprise) }
        let(:oc) { double(:oc, coordinator: coordinator_mock ) }
        let!(:applicator) { OrderCycleFormApplicator.new(oc, user) }

        describe "converting the existing variants of an exchange to a hash" do
          context "when nil is passed in" do
            let(:hash) { applicator.send(:persisted_variants_hash, nil) }

            it "returns an empty hash" do
              expect(hash).to eq({})
            end
          end

          context "when an exchange is passed in" do
            let(:v1) { create(:variant) }
            let(:exchange) { create(:exchange, variants: [v1]) }
            let(:hash) { applicator.send(:persisted_variants_hash, exchange) }

            it "returns a hash with variant ids as keys an all values set to true" do
              expect(hash.length).to be 1
              expect(hash[v1.id]).to be true
             end
          end
        end

        context "where a matching exchange does not exist" do
          let(:enterprise_mock) { double(:enterprise) }

          before do
            applicator.stub(:find_outgoing_exchange) { nil }
            expect(applicator).to receive(:editable_variant_ids_for_outgoing_exchange_between).
            with(coordinator_mock, enterprise_mock) { [1, 2, 3] }
          end

          it "converts exchange variant ids hash to an array of ids" do
            applicator.stub(:persisted_variants_hash) { {} }
            expect(Enterprise).to receive(:find) { enterprise_mock }
            ids = applicator.send(:outgoing_exchange_variant_ids, {:enterprise_id => 123, :variants => {'1' => true, '2' => false, '3' => true}})
            expect(ids).to eq [1, 3]
          end

          it "restricts exchange variant ids to those editable by the current user" do
            applicator.stub(:persisted_variants_hash) { {4 => true} }
            expect(Enterprise).to receive(:find) { enterprise_mock }
            ids = applicator.send(:outgoing_exchange_variant_ids, {:enterprise_id => 123, :variants => {'1' => true, '2' => false, '3' => true, '4' => false}})
            expect(ids).to eq [1, 3, 4]
          end

          it "overrides existing variants based on submitted data, when user has permission" do
            applicator.stub(:persisted_variants_hash) { {2 => true} }
            expect(Enterprise).to receive(:find) { enterprise_mock}
            ids = applicator.send(:outgoing_exchange_variant_ids, {:enterprise_id => 123, :variants => {'1' => true, '2' => false, '3' => true}})
            expect(ids).to eq [1, 3]
          end
        end

        context "where a matching exchange exists" do
          let(:enterprise_mock) { double(:enterprise) }
          let(:exchange_mock) { double(:exchange) }

          before do
            applicator.stub(:find_outgoing_exchange) { exchange_mock }
            expect(applicator).to receive(:editable_variant_ids_for_outgoing_exchange_between).
            with(coordinator_mock, enterprise_mock) { [1, 2, 3] }
          end

          it "converts exchange variant ids hash to an array of ids" do
            applicator.stub(:persisted_variants_hash) { {} }
            expect(exchange_mock).to receive(:receiver) { enterprise_mock }
            ids = applicator.send(:outgoing_exchange_variant_ids, {:enterprise_id => 123, :variants => {'1' => true, '2' => false, '3' => true}})
            expect(ids).to eq [1, 3]
          end

          it "restricts exchange variant ids to those editable by the current user" do
            applicator.stub(:persisted_variants_hash) { {4 => true} }
            expect(exchange_mock).to receive(:receiver) { enterprise_mock }
            ids = applicator.send(:outgoing_exchange_variant_ids, {:enterprise_id => 123, :variants => {'1' => true, '2' => false, '3' => true, '4' => false}})
            expect(ids).to eq [1, 3, 4]
          end

          it "overrides existing variants based on submitted data, when user has permission" do
            applicator.stub(:persisted_variants_hash) { {2 => true} }
            expect(exchange_mock).to receive(:receiver) { enterprise_mock }
            ids = applicator.send(:outgoing_exchange_variant_ids, {:enterprise_id => 123, :variants => {'1' => true, '2' => false, '3' => true}})
            expect(ids).to eq [1, 3]
          end
        end
      end

      describe "filtering exchanges for permission" do
        describe "checking permission on a single exchange" do
          it "returns true when it has permission" do
            e = double(:enterprise)
            ex = double(:exchange, participant: e)

            applicator = OrderCycleFormApplicator.new(nil, user)
            applicator.stub(:permitted_enterprises) { [e] }

            applicator.send(:permission_for, ex).should be_true
          end

          it "returns false otherwise" do
            e = double(:enterprise)
            ex = double(:exchange, participant: e)

            applicator = OrderCycleFormApplicator.new(nil, user)
            applicator.stub(:permitted_enterprises) { [] }

            applicator.send(:permission_for, ex).should be_false
          end
        end
      end
    end

    context "integration specs" do
      before(:all) do
        require 'spec_helper'
      end

      it "checks whether exchanges exist" do
        oc = FactoryGirl.create(:simple_order_cycle)
        exchange = FactoryGirl.create(:exchange, order_cycle: oc)
        applicator = OrderCycleFormApplicator.new(oc, user)

        applicator.send(:exchange_exists?, exchange.sender_id, exchange.receiver_id, exchange.incoming).should be_true
        applicator.send(:exchange_exists?, exchange.sender_id, exchange.receiver_id, !exchange.incoming).should be_false
        applicator.send(:exchange_exists?, exchange.receiver_id, exchange.sender_id, exchange.incoming).should be_false
        applicator.send(:exchange_exists?, exchange.sender_id, 999999, exchange.incoming).should be_false
        applicator.send(:exchange_exists?, 999999, exchange.receiver_id, exchange.incoming).should be_false
        applicator.send(:exchange_exists?, 999999, 888888, exchange.incoming).should be_false
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
            applicator.send(:add_exchange, sender.id, receiver.id, incoming, {:variant_ids => [variant1.id, variant2.id], :enterprise_fee_ids => [enterprise_fee1.id, enterprise_fee2.id]})
          end

          it "adds new exchanges" do
            exchange = Exchange.last
            expect(exchange.sender).to eq sender
            expect(exchange.receiver).to eq receiver
            expect(exchange.incoming).to eq incoming
            expect(exchange.variants).to match_array [variant1, variant2]
            expect(exchange.enterprise_fees).to match_array [enterprise_fee1, enterprise_fee2]

            applicator.send(:touched_exchanges).should == [exchange]
          end
        end

        context "as a user which does not manage the coorindator" do
          before do
            allow(applicator).to receive(:manages_coordinator?) { false }
            applicator.send(:add_exchange, sender.id, receiver.id, incoming, {:variant_ids => [variant1.id, variant2.id], :enterprise_fee_ids => [enterprise_fee1.id, enterprise_fee2.id]})
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

        let!(:exchange) { create(:exchange, order_cycle: oc, sender: sender, receiver: receiver, incoming: incoming, variant_ids: [variant1.id, variant2.id], enterprise_fee_ids: [enterprise_fee1.id, enterprise_fee2.id]) }

        context "as a manager of the coorindator" do
          before do
            allow(applicator).to receive(:manages_coordinator?) { true }
            allow(applicator).to receive(:manager_for) { false }
            allow(applicator).to receive(:permission_for) { true }
            applicator.send(:touched_exchanges=, [])
            applicator.send(:update_exchange, sender.id, receiver.id, incoming, {:variant_ids => [variant1.id, variant3.id], :enterprise_fee_ids => [enterprise_fee2.id, enterprise_fee3.id], :pickup_time => 'New Pickup Time', :pickup_instructions => 'New Pickup Instructions'})
          end

          it "updates the variants, enterprise fees and pickup information of the exchange" do
            exchange.reload
            expect(exchange.variants).to match_array [variant1, variant3]
            expect(exchange.enterprise_fees).to match_array [enterprise_fee2, enterprise_fee3]
            expect(exchange.pickup_time).to eq 'New Pickup Time'
            expect(exchange.pickup_instructions).to eq 'New Pickup Instructions'
            expect(applicator.send(:touched_exchanges)).to eq [exchange]
          end
        end

        context "as a manager of the participating enterprise" do
          before do
            allow(applicator).to receive(:manages_coordinator?) { false }
            allow(applicator).to receive(:manager_for) { true }
            allow(applicator).to receive(:permission_for) { true }
            applicator.send(:touched_exchanges=, [])
            applicator.send(:update_exchange, sender.id, receiver.id, incoming, {:variant_ids => [variant1.id, variant3.id], :enterprise_fee_ids => [enterprise_fee2.id, enterprise_fee3.id], :pickup_time => 'New Pickup Time', :pickup_instructions => 'New Pickup Instructions'})
          end

          it "updates the variants, enterprise fees and pickup information of the exchange" do
            exchange.reload
            expect(exchange.variants).to match_array [variant1, variant3]
            expect(exchange.enterprise_fees).to match_array [enterprise_fee2, enterprise_fee3]
            expect(exchange.pickup_time).to eq 'New Pickup Time'
            expect(exchange.pickup_instructions).to eq 'New Pickup Instructions'
            expect(applicator.send(:touched_exchanges)).to eq [exchange]
          end
        end

        context "where the participating enterprise is permitted for the user" do
          before do
            allow(applicator).to receive(:manages_coordinator?) { false }
            allow(applicator).to receive(:manager_for) { false }
            allow(applicator).to receive(:permission_for) { true }
            applicator.send(:touched_exchanges=, [])
            applicator.send(:update_exchange, sender.id, receiver.id, incoming, {:variant_ids => [variant1.id, variant3.id], :enterprise_fee_ids => [enterprise_fee2.id, enterprise_fee3.id], :pickup_time => 'New Pickup Time', :pickup_instructions => 'New Pickup Instructions'})
          end

          it "updates the variants in the exchange, but not the fees or pickup information" do
            exchange.reload
            expect(exchange.variants).to match_array [variant1, variant3]
            expect(exchange.enterprise_fees).to match_array [enterprise_fee1, enterprise_fee2]
            expect(exchange.pickup_time).to_not eq 'New Pickup Time'
            expect(exchange.pickup_instructions).to_not eq 'New Pickup Instructions'
            expect(applicator.send(:touched_exchanges)).to eq [exchange]
          end
        end
      end

      it "does not add exchanges it is not permitted to touch" do
        sender = FactoryGirl.create(:enterprise)
        receiver = FactoryGirl.create(:enterprise)
        oc = FactoryGirl.create(:simple_order_cycle)
        applicator = OrderCycleFormApplicator.new(oc, user)
        incoming = true

        expect do
          applicator.send(:touched_exchanges=, [])
          applicator.send(:add_exchange, sender.id, receiver.id, incoming)
        end.to change(Exchange, :count).by(0)
      end

      it "does not update exchanges it is not permitted to touch" do
        sender = FactoryGirl.create(:enterprise)
        receiver = FactoryGirl.create(:enterprise)
        oc = FactoryGirl.create(:simple_order_cycle)
        applicator = OrderCycleFormApplicator.new(oc, user)
        incoming = true
        exchange = FactoryGirl.create(:exchange, order_cycle: oc, sender: sender, receiver: receiver, incoming: incoming)
        variant1 = FactoryGirl.create(:variant)

        applicator.send(:touched_exchanges=, [])
        applicator.send(:update_exchange, sender.id, receiver.id, incoming, {:variant_ids => [variant1.id]})

        exchange.variants.should_not == [variant1]
      end
    end
  end
end
