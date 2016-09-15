require 'spec_helper'

module Spree
  module Admin
    describe VariantsController, type: :controller do
      before { login_as_admin }

      describe "search action" do
        let!(:p1) { create(:simple_product, name: 'Product 1') }
        let!(:p2) { create(:simple_product, name: 'Product 2') }
        let!(:v1) { p1.variants.first }
        let!(:v2) { p2.variants.first }
        let!(:vo) { create(:variant_override, variant: v1, hub: d, count_on_hand: 44) }
        let!(:d)  { create(:distributor_enterprise) }
        let!(:oc) { create(:simple_order_cycle, distributors: [d], variants: [v1]) }

        it "filters by distributor" do
          spree_get :search, q: 'Prod', distributor_id: d.id.to_s
          assigns(:variants).should == [v1]
        end

        it "applies variant overrides" do
          spree_get :search, q: 'Prod', distributor_id: d.id.to_s
          assigns(:variants).should == [v1]
          assigns(:variants).first.count_on_hand.should == 44
        end

        it "filters by order cycle" do
          spree_get :search, q: 'Prod', order_cycle_id: oc.id.to_s
          assigns(:variants).should == [v1]
        end

        it "does not filter when no distributor or order cycle is specified" do
          spree_get :search, q: 'Prod'
          assigns(:variants).should match_array [v1, v2]
        end
      end

      describe "price_estimate" do
        let(:user) { create(:user) }
        let!(:enterprise) { create(:enterprise, owner: user) }
        let(:unmanaged_enterprise) { create(:enterprise) }
        let!(:product) { create(:product) }
        let!(:variant) { create(:variant, product: product, unit_value: '100', price: 15.00, option_values: []) }
        let!(:enterprise_fee) { create(:enterprise_fee, amount: 3.50) }
        let!(:order_cycle) { create(:simple_order_cycle, coordinator: enterprise, orders_open_at: 2.days.from_now, orders_close_at: 7.days.from_now) }
        let!(:outgoing_exchange) { order_cycle.exchanges.create(sender: enterprise, receiver: enterprise, variants: [variant], enterprise_fees: [enterprise_fee]) }
        let!(:schedule) { create(:schedule, order_cycles: [order_cycle])}
        let(:unmanaged_schedule) { create(:schedule, order_cycles: [create(:simple_order_cycle, coordinator: unmanaged_enterprise)]) }

        context "json" do
          let(:params) { { format: :json, id: variant.id } }

          context 'as an enterprise user' do
            before { allow(controller).to receive(:spree_current_user) { user } }

            context "where I don't have access to the product in question" do
              it "redirects to unauthorized" do
                spree_get :price_estimate, params
                expect(response).to redirect_to spree.unauthorized_path
              end
            end

            context "where I have access to the product in question" do
              before do
                product.update_attribute(:supplier_id, enterprise.id)
              end

              context "but no shop_id is provided" do
                before { params.merge!({ schedule_id: schedule.id }) }

                it "returns an error" do
                  spree_get :price_estimate, params
                  expect(JSON.parse(response.body)['errors']).to eq ['Unauthorized']
                end
              end

              context "and an unmanaged shop_id is provided" do
                before { params.merge!({ shop_id: unmanaged_enterprise.id, schedule_id: schedule.id }) }

                it "returns an error" do
                  spree_get :price_estimate, params
                  expect(JSON.parse(response.body)['errors']).to eq ['Unauthorized']
                end
              end

              context "where no schedule_id is provided" do
                before { params.merge!({ shop_id: enterprise.id }) }

                it "returns an error" do
                  spree_get :price_estimate, params
                  expect(JSON.parse(response.body)['errors']).to eq ['Unauthorized']
                end
              end

              context "and an unmanaged schedule_id is provided" do
                before { params.merge!({ shop_id: enterprise.id, schedule_id: unmanaged_schedule.id }) }

                it "returns an error" do
                  spree_get :price_estimate, params
                  expect(JSON.parse(response.body)['errors']).to eq ['Unauthorized']
                end
              end

              context "where a managed shop_id and schedule_id are provided" do
                before { params.merge!({ shop_id: enterprise.id, schedule_id: schedule.id }) }

                it "returns a price estimate for the variant" do
                  spree_get :price_estimate, params

                  json_response = JSON.parse(response.body)
                  expect(json_response['price_with_fees']).to eq 18.5
                  expect(json_response['description']).to eq "#{variant.product.name} - 100g"
                end
              end
            end
          end
        end
      end
    end
  end
end
