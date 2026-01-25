# frozen_string_literal: false

RSpec.describe MapHelper do
  describe "#using_google_maps?" do
    it "returns true when a GOOGLE_MAPS_API_KEY is present" do
      stub_environment_variable("GOOGLE_MAPS_API_KEY", "ABC")

      expect(helper.using_google_maps?).to eq true
    end

    it "returns false if Open Street Map is enabled, even if a GOOGLE_MAPS_API_KEY is present" do
      stub_environment_variable("GOOGLE_MAPS_API_KEY", "ABC")
      ContentConfig.open_street_map_enabled = true

      expect(helper.using_google_maps?).to eq false
    end
  end

  private

  def stub_environment_variable(key, value)
    allow(ENV).to receive(:[]).and_call_original # Allow non-stubbed calls to ENV to proceed
    allow(ENV).to receive(:[]).with(key).and_return(value)
  end
end
