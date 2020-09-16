# frozen_string_literal: true

require 'spec_helper'

describe Spree::BaseHelper do
  include Spree::BaseHelper

  context "available_countries" do
    let(:country) { create(:country) }

    before do
      3.times { create(:country) }
    end

    context "with no checkout zone defined" do
      before do
        Spree::Config[:checkout_zone] = nil
      end

      it "return complete list of countries" do
        expect(available_countries.count).to eq Spree::Country.count
      end
    end

    context "with a checkout zone defined" do
      context "checkout zone is of type country" do
        before do
          @country_zone = create(:zone, name: "CountryZone")
          @country_zone.members.create(zoneable: country)
          Spree::Config[:checkout_zone] = @country_zone.name
        end

        it "return only the countries defined by the checkout zone" do
          expect(available_countries).to eq [country]
        end
      end

      context "checkout zone is of type state" do
        before do
          state_zone = create(:zone, name: "StateZone")
          state = create(:state, country: country)
          state_zone.members.create(zoneable: state)
          Spree::Config[:checkout_zone] = state_zone.name
        end

        it "return complete list of countries" do
          expect(available_countries.count).to eq Spree::Country.count
        end
      end
    end
  end

  context "pretty_time" do
    it "prints in a format" do
      expect(pretty_time(DateTime.new(2012, 5, 6, 13, 33))).to eq "May 06, 2012  1:33 PM"
    end
  end
end
