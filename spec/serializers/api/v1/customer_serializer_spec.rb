# frozen_string_literal: true

RSpec.describe Api::V1::CustomerSerializer do
  let(:customer) { create(:customer) }
  let(:serializer) { Api::V1::CustomerSerializer.new(customer) }
  let(:data) { serializer.serializable_hash[:data] }
  let(:attributes) { data[:attributes] }

  describe '#serializable_hash' do
    it 'includes data wrapper with type and id' do
      expect(data).to include(type: :customer, id: customer.id.to_s)
    end

    it 'serializes basic customer attributes' do
      expect(attributes).to include(
        id: customer.id,
        enterprise_id: customer.enterprise_id,
        first_name: customer.first_name,
        last_name: customer.last_name,
        code: customer.code,
        email: customer.email,
        customer_type: customer.customer_type
      )
    end

    it 'serializes tags from tag_list' do
      customer.update!(tag_list: ['vip', 'wholesale'])
      expect(serializer.serializable_hash[:data][:attributes][:tags]).to eq(['vip', 'wholesale'])
    end

    it 'serializes billing_address using AddressSerializer' do
      expect(attributes[:billing_address]).to include(
        first_name: customer.bill_address.firstname,
        last_name: customer.bill_address.lastname,
        street_address_1: customer.bill_address.address1,
        postal_code: customer.bill_address.zipcode,
        locality: customer.bill_address.city,
        phone: customer.bill_address.phone
      )
      expect(attributes[:billing_address][:region]).to be_a(Hash)
      expect(attributes[:billing_address][:country]).to be_a(Hash)
    end

    it 'serializes shipping_address using AddressSerializer' do
      customer.update!(ship_address: create(:address))
      hash = serializer.serializable_hash[:data][:attributes][:shipping_address]

      expect(hash).to include(
        first_name: customer.ship_address.firstname,
        last_name: customer.ship_address.lastname,
        street_address_1: customer.ship_address.address1
      )
    end

    context 'when shipping_address is nil' do
      it 'returns nil for shipping_address' do
        customer.update!(ship_address: nil)
        expect(serializer.serializable_hash[:data][:attributes][:shipping_address]).to be_nil
      end
    end

    it 'includes enterprise relationship with URL link' do
      expect(data[:relationships][:enterprise]).to include(
        data: { id: customer.enterprise_id.to_s, type: :enterprise }
      )
      expect(data[:relationships][:enterprise][:links][:related])
        .to include("/api/v1/enterprises/#{customer.enterprise_id}")
    end
  end

  describe 'conditional balance attribute' do
    context 'when customer has balance_value method' do
      it 'includes balance' do
        customer_with_balance = create(:customer)
          .tap { |c| allow(c).to receive(:balance_value).and_return(50.00) }
        
        expect(Api::V1::CustomerSerializer.new(customer_with_balance)
          .serializable_hash[:data][:attributes][:balance]).to eq(50.00)
      end
    end

    context 'when customer does not have balance_value method' do
      it 'excludes balance' do
        expect(serializer.serializable_hash[:data][:attributes])
          .not_to have_key(:balance)
      end
    end
  end

  describe 'enterprise customer type' do
    let(:enterprise_customer) {
      create(:customer,
             customer_type: 'enterprise',
             enterprise_name: 'Test Corp',
             enterprise_acn: '123456789',
             enterprise_charges_sales_tax: true)
    }

    it 'serializes enterprise-specific attributes' do
      hash = Api::V1::CustomerSerializer.new(enterprise_customer).serializable_hash

      expect(hash[:data][:attributes]).to include(
        customer_type: 'enterprise',
        enterprise_name: 'Test Corp',
        enterprise_acn: '123456789',
        enterprise_charges_sales_tax: true
      )
    end
  end

  describe '#to_json' do
    it 'generates valid JSON with customer data' do
      json = JSON.parse(serializer.to_json)

      expect(json['data']['id']).to eq(customer.id.to_s)
      expect(json['data']['type']).to eq('customer')
      expect(json['data']['attributes']['email']).to eq(customer.email)
    end
  end
end
