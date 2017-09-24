require 'spec_helper'

module OpenFoodNetwork::Reports
  describe BaseReport do
    context 'inheritance methods to search and filter for ui-grid reports' do
      let(:user) { create(:admin_user) }

      context 'blank object' do
        let(:report) { BaseReport.new(user, query: 'keyword') }
        it 'new instance accepts 3 arguments' do
          expect(report.params).to eq(query: 'keyword')
        end

        it 'gets search object via permissions' do
          expect(report.search).to be_instance_of(Ransack::Search)
        end

        it 'returns empty array of line_items' do
          expect(report.table_items).to be_empty
        end
      end

      context 'with line items' do
        let(:enterprise) { create(:distributor_enterprise) }
        let(:order_cycle) { create(:simple_order_cycle) }
        let(:order) { create(:order, completed_at: 1.day.ago, order_cycle: order_cycle, distributor: enterprise) }
        let(:line_item) { build(:line_item) }
        let(:report) { BaseReport.new(user) }

        before { order.line_items << line_item }

        it '#table_items returns one line_item' do
          expect(report.table_items).to eq([line_item])
        end

        it '#line_items returns one line_item' do
          expect(report.line_items).to eq([line_item])
        end

        it '#orders returns one order' do
          expect(report.orders).to eq([order])
        end

        it '#variants returns one variant' do
          expect(report.variants).to eq([line_item.variant])
        end

        it '#products returns one variant' do
          expect(report.products).to eq([line_item.product])
        end

        it '#distributors returns one variant' do
          expect(report.distributors).to eq([line_item.order.distributor])
        end

        context 'serializers' do
          it '#line_items returns one line_item' do
            expect(report.line_items_serialized.options[:each_serializer]).to eq(Api::Admin::Reports::LineItemSerializer)
          end

          it '#orders returns one order' do
            expect(report.orders_serialized.options[:each_serializer]).to eq(Api::Admin::Reports::OrderSerializer)
          end

          it '#variants returns one variant' do
            expect(report.variants_serialized.options[:each_serializer]).to eq(Api::Admin::Reports::VariantSerializer)
          end

          it '#products returns one variant' do
            expect(report.products_serialized.options[:each_serializer]).to eq(Api::Admin::Reports::ProductSerializer)
          end

          it '#distributors returns one variant' do
            expect(report.distributors_serialized.options[:each_serializer]).to eq(Api::Admin::Reports::EnterpriseSerializer)
          end
        end
      end
    end
  end
end
