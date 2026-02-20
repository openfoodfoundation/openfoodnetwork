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
        DataFoodConsortium::Connector::Address.new(
          nil,
          region: "Victoria",
          country: {
            scheme: "http",
            host: "publications.europa.eu",
            path: "/resource/authority/country/AUS",
          }
        )
      ],
      socialMedias: [
        DataFoodConsortium::Connector::SocialMedia.new(
          nil,
          name: "Facebook",
          url: "dfc_test_farm",
        )
      ],
    )
  }

  it "assigns data to a new enterprise object" do
    enterprise = subject.import

    expect(enterprise.id).to eq nil
    expect(enterprise.semantic_link.semantic_id).to eq "litefarm.org"
    expect(enterprise.name).to eq "Test Farm"
    expect(enterprise.address.state.name).to eq "Victoria"
    expect(enterprise.address.country.name).to eq "Australia"
    expect(enterprise.facebook).to eq "dfc_test_farm"
  end

  it "understands old country names" do
    dfc_enterprise.localizations[0].country = "France"
    dfc_enterprise.localizations[0].region = "Aquitaine"

    enterprise = subject.import

    expect(enterprise.id).to eq nil
    expect(enterprise.address.country.name).to eq "France"
    expect(enterprise.address.state.name).to eq "Aquitaine"
  end

  it "ignores errors during image import" do
    dfc_enterprise.logo = "invalid url"

    enterprise = subject.import

    expect(enterprise.name).to eq "Test Farm"
    expect(enterprise.logo.attached?).to eq false
  end
end
