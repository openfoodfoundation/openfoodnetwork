# frozen_string_literal: true

require 'spec_helper'

describe Spree::Address do
  describe "clone" do
    it "creates a copy of the address with the exception of the id, " \
       "updated_at and created_at attributes" do
      state = build_stubbed(:state)
      original = build_stubbed(:address,
                               address1: 'address1',
                               address2: 'address2',
                               alternative_phone: 'alternative_phone',
                               city: 'city',
                               country: state.country,
                               firstname: 'firstname',
                               lastname: 'lastname',
                               company: 'unused',
                               phone: 'phone',
                               state_id: state.id,
                               state_name: state.name,
                               zipcode: 'zip_code')

      cloned = original.clone

      expect(cloned.address1).to eq original.address1
      expect(cloned.address2).to eq original.address2
      expect(cloned.alternative_phone).to eq original.alternative_phone
      expect(cloned.city).to eq original.city
      expect(cloned.country_id).to eq original.country_id
      expect(cloned.firstname).to eq original.firstname
      expect(cloned.lastname).to eq original.lastname
      expect(cloned.company).to eq original.company
      expect(cloned.phone).to eq original.phone
      expect(cloned.state_id).to eq original.state_id
      expect(cloned.state_name).to eq original.state_name
      expect(cloned.zipcode).to eq original.zipcode

      expect(cloned.id).to_not eq original.id
      expect(cloned.created_at).to_not eq original.created_at
      expect(cloned.updated_at).to_not eq original.updated_at
    end
  end

  context "aliased attributes" do
    let(:address) { Spree::Address.new }

    it "first_name" do
      address.firstname = "Ryan"
      expect(address.first_name).to eq "Ryan"
    end

    it "last_name" do
      address.lastname = "Bigg"
      expect(address.last_name).to eq "Bigg"
    end
  end

  context "validation" do
    before do
      configure_spree_preferences do |config|
        config.address_requires_state = true
      end
    end

    let(:state) { build_stubbed(:state, name: 'maryland', abbr: 'md') }
    let(:country) { state.country }
    let(:address) { build_stubbed(:address, country: country, state: state) }

    before do
      country.states_required = true
    end

    it "errors when state_name is nil" do
      address.state_name = nil
      address.state = nil
      expect(address).to_not be_valid
    end

    it "full state name is in state_name and country does contain that state" do
      allow(country).to receive_message_chain(:states, :find_all_by_name_or_abbr) do
        [build_stubbed(:state, name: 'alabama', abbr: 'al')]
      end

      address.state_name = 'alabama'
      expect(address).to be_valid
      expect(address.state.name).to eq 'alabama'
      expect(address.state_name).to eq 'alabama'
    end

    it "state abbr is in state_name and country does contain that state" do
      allow(country).to receive_message_chain(:states, :find_all_by_name_or_abbr) { [state] }
      address.state_name = state.abbr
      expect(address).to be_valid
      expect(address.state.abbr).to eq state.abbr
      expect(address.state_name).to eq state.name
    end

    it "both state and state_name are entered and country does contain the state" do
      allow(country).to receive_message_chain(:states, :find_all_by_name_or_abbr) { [state] }
      address.state = state
      address.state_name = 'maryland'
      expect(address).to be_valid
      expect(address.state_name).to eq 'maryland'
    end

    it "address_requires_state preference is false" do
      Spree::Config.set address_requires_state: false
      address.state = nil
      address.state_name = nil
      expect(address).to be_valid
    end

    it "requires phone" do
      address.phone = ""
      address.valid?
      expect(address.errors[:phone].first).to eq "can't be blank"
    end

    it "requires zipcode" do
      address.zipcode = ""
      address.valid?
      expect(address.errors[:zipcode].first).to eq "can't be blank"
    end

    context "zipcode not required" do
      before { allow(address).to receive(:require_zipcode?) { false } }

      it "shows no errors when phone is blank" do
        address.zipcode = ""
        address.valid?
        expect(address.errors[:zipcode]).to be_empty
      end
    end
  end

  context ".default" do
    it "sets up a new record the default country" do
      expect(Spree::Address.default.country).to eq DefaultCountry.country
    end

    # Regression test for #1142

    context "The default country code is set to an invalid value" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("DEFAULT_COUNTRY_CODE").and_return("notacountry")
      end

      it "uses the first available country" do
        expect(Spree::Address.default.country).to eq Spree::Country.first
      end
    end
  end

  context '#full_name' do
    context 'both first and last names are present' do
      let(:address) { build(:address, firstname: 'Michael', lastname: 'Jackson') }
      specify { expect(address.full_name).to eq 'Michael Jackson' }
    end

    context 'first name is blank' do
      let(:address) { build(:address, firstname: nil, lastname: 'Jackson') }
      specify { expect(address.full_name).to eq 'Jackson' }
    end

    context 'last name is blank' do
      let(:address) { build(:address, firstname: 'Michael', lastname: nil) }
      specify { expect(address.full_name).to eq 'Michael' }
    end

    context 'both first and last names are blank' do
      let(:address) { build(:address, firstname: nil, lastname: nil) }
      specify { expect(address.full_name).to eq '' }
    end
  end

  context '#state_text' do
    context 'both name and abbr is present' do
      let(:state) { build(:state, name: 'virginia', abbr: 'va') }
      let(:address) { build(:address, state: state) }
      specify { expect(address.state_text).to eq 'va' }
    end

    context 'only name is present' do
      let(:state) { build(:state, name: 'virginia', abbr: nil) }
      let(:address) { build(:address, state: state) }
      specify { expect(address.state_text).to eq 'virginia' }
    end
  end

  describe "ransacker :full_name" do
    it "searches for records with matching full names" do
      address1 = create(:address, firstname: 'John', lastname: 'Doe')
      address2 = create(:address, firstname: 'Jane', lastname: 'Smith')

      result1 = described_class.ransack(full_name_cont: 'John Doe').result
      expect(result1).to include(address1)
      expect(result1).not_to include(address2)

      result2 = described_class.ransack(full_name_cont: 'Jane Smith').result
      expect(result2).to include(address2)
      expect(result2).not_to include(address1)
    end
  end
end
