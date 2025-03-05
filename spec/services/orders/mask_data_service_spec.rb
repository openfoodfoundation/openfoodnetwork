# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Orders::MaskDataService do
  describe '#call' do
    let(:distributor) { create(:enterprise) }
    let(:order) { create(:order, distributor:, ship_address: create(:address)) }

    shared_examples "mask customer name" do
      it 'masks the full name' do
        described_class.new(order).call

        expect(order.bill_address.attributes).to include(
          'firstname' => 'HIDDEN',
          'lastname' => ''
        )
        expect(order.ship_address.attributes).to include(
          'firstname' => 'HIDDEN',
          'lastname' => ''
        )
      end
    end

    shared_examples "mask customer contact data" do
      it 'masks personal phone and email' do
        described_class.new(order).call

        expect(order.bill_address.attributes).to include('phone' => '')
        expect(order.ship_address.attributes).to include('phone' => '')

        expect(order.email).to eq('HIDDEN')
      end
    end

    shared_examples "mask customer address" do
      it 'masks personal addresses' do
        described_class.new(order).call

        expect(order.bill_address.attributes).to include(
          'address1' => '',
          'address2' => '',
          'city' => '',
          'zipcode' => '',
          'state_id' => nil
        )

        expect(order.ship_address.attributes).to include(
          'address1' => '',
          'address2' => '',
          'city' => '',
          'zipcode' => '',
          'state_id' => nil
        )
      end
    end

    context 'when displaying customer names is allowed' do
      before { distributor.show_customer_names_to_suppliers = true }

      include_examples "mask customer contact data"
      include_examples "mask customer address"

      it 'does not mask the full name' do
        described_class.new(order).call

        expect(order.bill_address.attributes).not_to include(
          firstname: 'HIDDEN',
          lastname: ''
        )
        expect(order.ship_address.attributes).not_to include(
          firstname: 'HIDDEN',
          lastname: ''
        )
      end
    end

    context 'when displaying customer names is not allowed' do
      before { distributor.show_customer_names_to_suppliers = false }

      include_examples "mask customer name"
      include_examples "mask customer contact data"
      include_examples "mask customer address"
    end
  end
end
