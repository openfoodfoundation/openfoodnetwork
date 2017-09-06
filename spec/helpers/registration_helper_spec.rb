require 'spec_helper'

describe RegistrationHelper do
  describe '#state_options_query' do
    subject { helper.state_options_query }

    before { allow(Rails.configuration).to receive(:state_text_attribute).and_return(attribute) }

    context 'and set to `abbr`' do
      let(:attribute) { 'abbr' }
      let(:query_with_abbr) do
        's.id as s.abbr for s in enterprise.country.states'
      end

      it 'returns a query using `abbr` attribute' do
        expect(subject).to eq(query_with_abbr)
      end
    end

    context 'and set to `name`' do
      let(:attribute) { 'name' }
      let(:query_with_name) do
        's.id as s.name for s in enterprise.country.states'
      end

      it 'returns a query using `name` attribute' do
        expect(subject).to eq(query_with_name)
      end
    end
  end
end
