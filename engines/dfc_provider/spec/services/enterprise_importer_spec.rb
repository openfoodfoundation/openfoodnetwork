# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe EnterpriseImporter do
  subject { EnterpriseImporter.new(owner, dfc_enterprise) }
  let(:owner) { Spree::User.new }
  let(:dfc_enterprise) {
    DataFoodConsortium::Connector::Enterprise.new(
      "litefarm.org",
      name: "Test Farm",
      localizations: [
        DataFoodConsortium::Connector::Address.new(nil)
      ],
    )
  }

  it "assigns data to a new enterprise object" do
    enterprise = subject.import

    expect(enterprise.id).to eq nil
    expect(enterprise.semantic_link.semantic_id).to eq "litefarm.org"
    expect(enterprise.name).to eq "Test Farm"
  end

  it "ignores errors during image import" do
    dfc_enterprise.logo = "invalid url"

    enterprise = subject.import

    expect(enterprise.name).to eq "Test Farm"
    expect(enterprise.logo.attached?).to eq false
  end
end
