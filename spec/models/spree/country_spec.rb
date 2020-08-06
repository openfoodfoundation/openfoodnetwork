# frozen_string_literal: true

require 'spec_helper'

describe Spree::Country do
  it "can find all countries group by states required" do
    country_states_required = Spree::Country.create({ name: "Canada",
                                                      iso_name: "CAN",
                                                      states_required: true })
    country_states_not_required = Spree::Country.create({ name: "France",
                                                          iso_name: "FR",
                                                          states_required: false })
    states_required = Spree::Country.states_required_by_country_id
    expect(states_required[country_states_required.id.to_s]).to be_truthy
    expect(states_required[country_states_not_required.id.to_s]).to be_falsy
  end

  it "returns that the states are required for an invalid country" do
    expect(Spree::Country.states_required_by_country_id['i do not exit']).to be_truthy
  end
end
