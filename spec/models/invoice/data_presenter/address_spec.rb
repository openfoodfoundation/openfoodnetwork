# frozen_string_literal: true

RSpec.describe Invoice::DataPresenter::Address do
  subject(:presenter) { described_class.new(data) }

  let(:data) do
    {
      city: "Luzern",
      zipcode: "6004",
      state: { name: "Luzern" }
    }
  end

  describe "#address_part2" do
    it "displays city, zipcode and state by default" do
      expect(presenter.address_part2).to eq("Luzern, 6004, Luzern")
    end

    context "when postal_code_first format is configured" do
      before do
        allow(Spree::Config).to receive(:[])
          .with(:address_display_format).and_return("postal_code_first")
      end

      it "displays postal code before city and omits state" do
        expect(presenter.address_part2).to eq("6004, Luzern")
      end
    end
  end

  describe "#full_address" do
    let(:data) do
      {
        address1: "Street 1",
        address2: "Suite 2",
        city: "Luzern",
        zipcode: "6004",
        state: { name: "Luzern" }
      }
    end

    it "displays address in default format" do
      expect(presenter.full_address).to eq("Street 1, Suite 2, Luzern, 6004, Luzern")
    end

    context "when postal_code_first format is configured" do
      before do
        allow(Spree::Config).to receive(:[])
          .with(:address_display_format).and_return("postal_code_first")
      end

      it "displays postal code before city and omits state" do
        expect(presenter.full_address).to eq("Street 1, Suite 2, 6004, Luzern")
      end
    end
  end
end
