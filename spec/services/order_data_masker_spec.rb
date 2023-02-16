# frozen_string_literal: true

require 'spec_helper'

describe OrderDataMasker do
  describe '#call' do
    let(:distributor) { create(:enterprise) }
    let(:order) { create(:order, distributor: distributor, ship_address: create(:address)) }

    context 'when displaying customer names is allowed' do
      before { distributor.show_customer_names_to_suppliers = true }

      it 'masks personal addresses and email' do
        described_class.new(order).call

        expect(order.bill_address.attributes).to include(
          'phone' => '',
          'address1' => '',
          'address2' => '',
          'city' => '',
          'zipcode' => '',
          'state_id' => nil
        )

        expect(order.ship_address.attributes).to include(
          'phone' => '',
          'address1' => '',
          'address2' => '',
          'city' => '',
          'zipcode' => '',
          'state_id' => nil
        )

        expect(order.email).to eq('HIDDEN')
      end

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

      it 'masks personal addresses and email' do
        described_class.new(order).call

        expect(order.bill_address.attributes).to include(
          'phone' => '',
          'address1' => '',
          'address2' => '',
          'city' => '',
          'zipcode' => '',
          'state_id' => nil
        )

        expect(order.ship_address.attributes).to include(
          'phone' => '',
          'address1' => '',
          'address2' => '',
          'city' => '',
          'zipcode' => '',
          'state_id' => nil
        )

        expect(order.email).to eq('HIDDEN')
      end

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
  end
end
