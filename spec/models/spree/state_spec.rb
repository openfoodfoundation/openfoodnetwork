# frozen_string_literal: true

require 'spec_helper'

describe Spree::State do
  before(:all) do
    Spree::State.destroy_all
  end

  it "can find a state by name or abbr" do
    state = create(:state, name: "California", abbr: "CA")
    expect(Spree::State.find_all_by_name_or_abbr("California")).to include(state)
    expect(Spree::State.find_all_by_name_or_abbr("CA")).to include(state)
  end
end
