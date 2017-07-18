require 'spec_helper'

describe Spree::BaseHelper, type: :helper do
  describe "#link_to_remove_fields_without_url" do
    let(:name) { 'Hola' }
    let(:form) { double('form_for', hidden_field: '<input type="hidden" name="_method" value="destroy">') }
    let(:options) { {} }

    subject { helper.link_to_remove_fields_without_url(name, form, options) }

    it 'returns an `a` tag followed by a hidden `input` tag' do
      expect(subject).to eq("<a class=\"remove_fields  icon_link with-tip icon-trash\" data-action=\"remove\" title=\"Remove\"><span class='text'>Hola</span></a><input type=\"hidden\" name=\"_method\" value=\"destroy\">")
    end
  end
end
