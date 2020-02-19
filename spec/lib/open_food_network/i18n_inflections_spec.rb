# frozen_string_literal: true

require 'spec_helper'
require 'open_food_network/i18n_inflections'

describe OpenFoodNetwork::I18nInflections do
  let(:subject) { described_class }

  it "returns the same word if no plural is known" do
    expect(subject.pluralize("foo", 2)).to eq "foo"
  end

  it "finds the plural of a word" do
    expect(subject.pluralize("bunch", 2)).to eq "bunches"
  end

  it "finds the singular of a word" do
    expect(subject.pluralize("bunch", 1)).to eq "bunch"
  end

  it "ignores upper case" do
    expect(subject.pluralize("Bunch", 2)).to eq "bunches"
  end

  it "switches locales" do
    skip "French plurals not available yet"
    I18n.with_locale(:fr) do
      expect(subject.pluralize("bouquet", 2)).to eq "bouquets"
    end
  end

  it "builds the lookup table once" do
    # Cache the table:
    subject.pluralize("bunch", 2)

    # Expect only one call for the plural:
    expect(I18n).to receive(:t).once.and_call_original
    subject.pluralize("bunch", 2)
  end
end
