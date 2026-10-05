# frozen_string_literal: true

RSpec.describe Invoice::DataPresenter::Customer do
  subject(:presenter) { described_class.new(data) }

  let(:data) do
    {
      code: "C001",
      email: "customer@example.com",
      customer_type: "individual",
      enterprise_name: "Da Box",
      enterprise_abn: "123456789abn",
      enterprise_acn: "11223344556acn",
      enterprise_charges_sales_tax: true
    }
  end

  it { is_expected.to be_a(Invoice::DataPresenter::Base) }

  describe "attribute readers" do
    it "exposes code" do
      expect(presenter.code).to eq("C001")
    end

    it "exposes email" do
      expect(presenter.email).to eq("customer@example.com")
    end

    it "exposes customer_type" do
      expect(presenter.customer_type).to eq("individual")
    end

    it "exposes enterprise_name" do
      expect(presenter.enterprise_name).to eq("Da Box")
    end

    it "exposes enterprise_abn" do
      expect(presenter.enterprise_abn).to eq("123456789abn")
    end

    it "exposes enterprise_acn" do
      expect(presenter.enterprise_acn).to eq("11223344556acn")
    end

    it "exposes enterprise_charges_sales_tax" do
      expect(presenter.enterprise_charges_sales_tax).to be(true)
    end
  end

  context "when data is nil" do
    let(:data) { nil }

    it "returns nil for all attributes" do
      expect(presenter.code).to be_nil
      expect(presenter.email).to be_nil
      expect(presenter.customer_type).to be_nil
      expect(presenter.enterprise_name).to be_nil
      expect(presenter.enterprise_acn).to be_nil
      expect(presenter.enterprise_abn).to be_nil
      expect(presenter.enterprise_charges_sales_tax).to be_nil
    end
  end

  context "with data from a generated invoice" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:order) { create(:order, :with_line_item, :completed, distributor:) }
    let(:data) { create(:invoice, order:).reload.data[:customer] }

    it "exposes the enterprise details of an enterprise customer" do
      order.customer.update!(customer_type: "enterprise", enterprise_name: "Da Box",
                             enterprise_abn: "123", enterprise_acn: "456")

      expect(presenter).to be_enterprise
      expect(presenter).to have_attributes(enterprise_name: "Da Box", enterprise_abn: "123",
                                           enterprise_acn: "456")
    end

    it "is not an enterprise for an individual customer" do
      expect(presenter).not_to be_enterprise
    end
  end

  context "when attributes are missing from data" do
    let(:data) { {} }

    it "returns nil for missing attributes" do
      expect(presenter.code).to be_nil
      expect(presenter.enterprise_name).to be_nil
    end
  end
end
