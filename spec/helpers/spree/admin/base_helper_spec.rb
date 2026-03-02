# frozen_string_literal: true

RSpec.describe Spree::Admin::BaseHelper do
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

  describe "#preference_field_options" do
    subject { helper.preference_field_options(options) }

    context 'when type is integer' do
      let(:options) { { type: :integer } }

      it 'returns correct options' do
        expect(subject).to eq({ size: nil, class: 'input_integer', step: 1, readonly: nil,
                                disabled: nil })
      end
    end

    context 'when type is decimal' do
      let(:options) { { type: :decimal } }

      it 'returns correct options' do
        expect(subject).to eq({ size: nil, class: 'input_integer', step: :any, readonly: nil,
                                disabled: nil })
      end
    end

    context 'when type is boolean' do
      let(:options) { { type: :boolean } }

      it 'returns correct options' do
        expect(subject).to eq({ readonly: nil, disabled: nil, size: nil })
      end
    end

    context 'when type is password' do
      let(:options) { { type: :password } }

      it 'returns correct options' do
        expect(subject).to eq({ size: nil, class: 'password_string fullwidth', readonly: nil,
                                disabled: nil })
      end
    end

    context 'when type is text' do
      let(:options) { { type: :text } }

      it 'returns correct options' do
        expect(subject).to eq({ size: nil, rows: 15, cols: 85, class: 'fullwidth', readonly: nil,
                                disabled: nil })
      end
    end

    context 'when type is string' do
      let(:options) { { type: :string } }

      it 'returns correct options' do
        expect(subject).to eq({ size: nil, class: 'input_string fullwidth', readonly: nil,
                                disabled: nil })
      end
    end

    context 'when readonly, disabled and size are set' do
      let(:options) { { type: :integer, readonly: true, disabled: false, size: 20 } }

      it 'returns correct options' do
        expect(subject).to eq({ size: 20, class: 'input_integer', step: 1, readonly: true,
                                disabled: false })
      end
    end
  end
end
