# frozen_string_literal: true

require "spec_helper"

describe ProductComponent, type: :component do
  let(:product) { create(:simple_product) }

  describe 'unit' do
    before do
      render_inline(ProductComponent.new(
        product: product, columns: [{ label: "Unit", value: "unit", sortable: false }]
      ))
    end

    it 'concatenates the unit value and the unit description' do
      expect(page.find('.unit')).to have_content '1.0 weight'
    end
  end

  describe 'category' do
    let(:product) do
      product = create(:simple_product)
      product.taxons << create(:taxon, name: 'random')

      product
    end

    before do
      render_inline(ProductComponent.new(
        product: product, columns: [{ label: "Category", value: "category", sortable: false }]
      ))
    end

    it "joins the categories' name" do
      expect(page.find('.category')).to have_content(product.taxons.map(&:name).join(', '))
    end
  end

  describe 'on_hand' do
    let(:product) { create(:simple_product, on_hand: on_hand) }
    let(:on_hand) { 5 }

    before do
      render_inline(ProductComponent.new(
        product: product, columns: [{ label: "On Hand", value: "on_hand", sortable: false }]
      ))
    end

    it 'return product on_hand' do
      expect(page.find('.on_hand')).to have_content(on_hand)
    end

    context 'when on_hand is nil' do
      let(:on_hand) { nil }

      it 'returns 0' do
        expect(page.find('.on_hand')).to have_content(0.to_s)
      end
    end
  end

  # This also covers import_date
  describe 'available_on' do
    let(:product) { create(:simple_product, available_on: available_on) }
    let(:available_on) { Time.zone.now }

    before do
      render_inline(ProductComponent.new(
        product: product, columns: [{ label: "Available On", value: "available_on", sortable: false }]
      ))
    end

    it 'return formated available_on' do
      expect(page.find('.available_on')).to have_content(available_on.strftime('%F %T'))
    end

    context 'when available_on is nil' do
      let(:available_on) { nil }

      it 'returns an empty string' do
        expect(page.find('.available_on')).to have_content('')
      end
    end
  end
end
