# frozen_string_literal: true

require 'spec_helper'

describe Spree::State do
  before(:all) do
    Spree::State.destroy_all
  end

  it "can find a state by name or abbr" do
    state = create(:state, name: "California", abbr: "CA")
    Spree::State.find_all_by_name_or_abbr("California").should include(state)
    Spree::State.find_all_by_name_or_abbr("CA").should include(state)
  end

  it "can find all states group by country id" do
    state = create(:state)
    country_hash = { state.country_id.to_s => [[state.id, state.name]] }
    expect(Spree::State.states_group_by_country_id).to eq country_hash
  end
end
