# frozen_string_literal: true

require_relative "../spec_helper"

# These tests depend on valid OpenID Connect client credentials in your
# `.env.test.local` file.
#
#     OPENID_APP_ID="..."
#     OPENID_APP_SECRET="..."
RSpec.describe DfcImporter do
  let(:endpoint) { "https://api.beta.litefarm.org/dfc/enterprises/" }

  it "fetches a list of enterprises", :vcr do
    expect {
      subject.import_enterprise_profiles("lf-dev", endpoint)
    }.to have_enqueued_mail(Spree::UserMailer, :confirmation_instructions).exactly(7)
      .and have_enqueued_mail(EnterpriseMailer, :welcome).exactly(6)

    # You can show the emails in your browser.
    # Consider creating a test helper if you find this useful elsewhere.
    # allow(ApplicationMailer).to receive(:delivery_method).and_return(:letter_opener)
    # perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob)

    # Repeating works without creating duplicates:
    expect {
      subject.import_enterprise_profiles("lf-dev", endpoint)
    }.not_to have_enqueued_mail

    semantic_id = "https://api.beta.litefarm.org/dfc/enterprises/23bfd9b1-98b5-4b91-88e5-efa7cb36219d"
    enterprise = Enterprise.joins(:semantic_link).find_by(semantic_link: { semantic_id: })
    expect(enterprise.name).to eq "DFC Test Farm Beta (All Supplied Fields)"
    expect(enterprise.email_address).to eq "dfcshop@example.com"
    expect(enterprise.logo.blob.content_type).to eq "image/webp"
    expect(enterprise.logo.blob.byte_size).to eq 8974
    expect(enterprise.visible).to eq "public"

    expect(subject.errors.count).to eq 2
    expect(subject.errors.first.record.semantic_link.semantic_id)
      .to eq "https://api.beta.litefarm.org/dfc/enterprises/13152ea2-8d19-4309-a443-c95d8879d299"
    expect(subject.errors.first.message)
      .to eq "Validation failed: Address zipcode can't be blank, Address is invalid"
  end

  it "imports farms in DFC v2 format" do
    expect_any_instance_of(DfcPlatformRequest).to receive(:call) do
      ExampleJson.read("litefarm_v2")
    end

    expect {
      subject.import_enterprise_profiles("lf-dev", endpoint)
    }.to have_enqueued_mail(Spree::UserMailer, :confirmation_instructions).exactly(3)
      .and have_enqueued_mail(EnterpriseMailer, :welcome).exactly(3)

    semantic_id = "https://api.beta.litefarm.org/dfc/enterprises/79eba89b-0c26-414f-9f74-50aeb537519b"
    enterprise = Enterprise.joins(:semantic_link).find_by(semantic_link: { semantic_id: })
    expect(enterprise.name).to eq "Happy Acres Farm"
    expect(enterprise.email_address).to eq "info@happyacres.com"
    expect(enterprise.visible).to eq "public"
    expect(enterprise.properties.count).to eq 2
    expect(enterprise.properties.pluck(:name)).to match_array ["Organic", "Biodynamic"]

    expect(subject.errors).to be_nil
  end

  describe ".import_profile" do
    it "updates certificates" do
      farm_data = ExampleJson.read("litefarm_v2_2026_07_22_beta_dfc_farm_three")
      graph = DfcLoader.connector_v2.import(farm_data).to_a
      farm = graph[1]

      expect {
        subject.import_profile(farm)
      }.to change { Enterprise.count }.by(1)

      enterprise = Enterprise.last
      expect(enterprise.properties.count).to eq 1

      enterprise.properties.destroy_all

      expect {
        subject.import_profile(farm)
        enterprise.reload
      }.to change { Enterprise.count }.by(0)
        .and change { enterprise.properties.count }.by(1)
      expect(enterprise.properties.pluck(:name)).to eq ["Biodynamic"]

      enterprise.properties.update_all(name: "Updated prop")

      expect {
        subject.import_profile(farm)
        enterprise.reload
      }.to change { enterprise.properties.count }.by(1)
      expect(enterprise.properties.pluck(:name)).to match_array ["Biodynamic", "Updated prop"]
    end
  end
end
