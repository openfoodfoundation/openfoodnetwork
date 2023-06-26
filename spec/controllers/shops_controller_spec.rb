# frozen_string_literal: true

require 'spec_helper'

describe ShopsController, type: :controller do
  include WebHelper
  render_views

  let!(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }

  it 'renders distributed product properties' do
    product_property = create(:property, presentation: 'eggs')
    product = create(:product, properties: [product_property])
    producer = create(:supplier_enterprise)

    create(
      :simple_order_cycle,
      coordinator: distributor,
      suppliers: [producer],
      distributors: [distributor],
      variants: [product.variants]
    )

    get :index

    expect(response.body)
      .to match(/"distributed_properties":\[{"id":\d+,"name":"eggs","presentation":"eggs"}\]/)
  end

  it 'renders distributed producer properties' do
    producer_property = create(:property, presentation: 'certified')
    producer = create(:supplier_enterprise, properties: [producer_property])
    product = create(:product)

    create(
      :simple_order_cycle,
      coordinator: distributor,
      suppliers: [producer],
      distributors: [distributor],
      variants: [product.variants]
    )

    get :index

    expect(response.body)
      .to match(/"distributed_properties":\[{"id":\d+,"name":
                "certified","presentation":"certified"}\]/x)
  end

  it 'renders distributed properties' do
    duplicate_property = create(:property, presentation: 'dairy')
    producer = create(:supplier_enterprise, properties: [duplicate_property])
    property = create(:property, presentation: 'dairy')

    product = create(:product, properties: [property])
    producer.supplied_products << product

    create(
      :simple_order_cycle,
      coordinator: distributor,
      suppliers: [producer],
      distributors: [distributor],
      variants: [product.variants]
    )

    get :index

    expect(response.body)
      .to match(/"distributed_properties":\[{"id":\d+,"name":"dairy","presentation":"dairy"}\]/)
  end
end
