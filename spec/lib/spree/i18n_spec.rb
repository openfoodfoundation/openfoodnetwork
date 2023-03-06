# frozen_string_literal: true

require 'rspec/expectations'
require 'spree/i18n'

describe "i18n" do
  before do
    I18n.backend.store_translations(
      :en,
      {
        spree: {
          foo: "bar",
          bar: {
            foo: "bar within bar scope",
            invalid: nil,
            legacy_translation: "back in the day..."
          },
          invalid: nil,
          legacy_translation: "back in the day..."
        }
      }
    )

    allow(ActionView::Base).
      to receive(:raise_on_missing_translations).
      and_return(false)
  end

  it "translates within the spree scope" do
    expect(Spree.t(:foo)).to eql("bar")
    expect(Spree.translate(:foo)).to eql("bar")
  end

  it "translates within the spree scope using a path" do
    allow(Spree).to receive(:virtual_path).and_return('bar')

    expect(Spree.t('.legacy_translation')).to eql("back in the day...")
    expect(Spree.translate('.legacy_translation')).to eql("back in the day...")
  end

  it "raise error without any context when using a path" do
    expect {
      Spree.t('.legacy_translation')
    }.to raise_error RuntimeError

    expect {
      Spree.translate('.legacy_translation')
    }.to raise_error RuntimeError
  end

  it "prepends a string scope" do
    expect(Spree.t(:foo, scope: "bar")).to eql("bar within bar scope")
  end

  it "prepends to an array scope" do
    expect(Spree.t(:foo, scope: ["bar"])).to eql("bar within bar scope")
  end

  it "returns two translations" do
    expect(Spree.t([:foo, 'bar.foo'])).to eql(["bar", "bar within bar scope"])
  end

  it "returns reasonable string for missing translations" do
    expect(Spree.t(:missing_entry)).to include("<span")
  end
end
