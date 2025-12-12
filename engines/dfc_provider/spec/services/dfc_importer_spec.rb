# frozen_string_literal: true

require_relative "../spec_helper"

# These tests depend on valid OpenID Connect client credentials in your
# `.env.test.local` file.
#
#     OPENID_APP_ID="..."
#     OPENID_APP_SECRET="..."
RSpec.describe DfcImporter do
  let(:endpoint) { "https://api.beta.litefarm.org/dfc/enterprises/" }
  let(:semantic_id) {
    "https://api.beta.litefarm.org/dfc/enterprises/23bfd9b1-98b5-4b91-88e5-efa7cb36219d"
  }

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
end
