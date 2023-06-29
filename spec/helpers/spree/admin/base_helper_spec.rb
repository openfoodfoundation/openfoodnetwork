# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::BaseHelper, type: :helper do
  helper 'spree/admin/navigation'

  describe "#link_to_remove_fields" do
    let(:name) { 'Hola' }
    let(:form) {
      double('form_for', hidden_field: '<input type="hidden" name="_method" value="destroy">')
    }
    let(:options) { {} }

    subject { helper.link_to_remove_fields(name, form, options) }

    it 'returns an `a` tag followed by a hidden `input` tag' do
      expect(subject).to eq("<a class=\"remove_fields  icon_link with-tip icon-trash\" " \
                            "data-action=\"remove\" title=\"Remove\" href=\"#\">" \
                            "<span class='text'>Hola</span></a>&lt;input type=&quot;hidden&quot; " \
                            "name=&quot;_method&quot; value=&quot;destroy&quot;&gt;")
    end
  end
end
