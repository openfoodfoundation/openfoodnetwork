# frozen_string_literal: true

require 'spec_helper'

class TestHelper < ActionView::Base; end

describe BulkFormBuilder do
  describe '#text_field' do
    let(:product) { create(:product) }
    let(:form) { BulkFormBuilder.new(:product, product, self, {}) }

    it { expect(form.text_field(:name)).not_to include "changed" }

    context "attribute has been changed" do
      before { product.assign_attributes name: "updated name" }

      it { expect(form.text_field(:name)).to include "changed" }

      context "and saved" do
        before { product.save }

        it { expect(form.text_field(:name)).not_to include "changed" }
      end
    end
  end
end
