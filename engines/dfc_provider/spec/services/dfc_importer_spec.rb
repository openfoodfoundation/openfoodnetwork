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
    }.to have_enqueued_mail(Spree::UserMailer, :confirmation_instructions)
      .and have_enqueued_mail(EnterpriseMailer, :welcome).twice

    # You can show the emails in your browser.
    # Consider creating a test helper if you find this useful elsewhere.
    # allow(ApplicationMailer).to receive(:delivery_method).and_return(:letter_opener)
    # perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob)

    enterprise = Enterprise.last
    expect(enterprise.semantic_link.semantic_id).to match /litefarm\.org/

    # Repeating works without creating duplicates:
    expect {
      subject.import_enterprise_profiles("lf-dev", endpoint)
    }.not_to have_enqueued_mail

    expect(enterprise.name).to eq "DFC Test Farm Beta (All Supplied Fields)"
    expect(enterprise.email_address).to eq "dfcshop@example.com"
    expect(enterprise.logo.blob.content_type).to eq "image/webp"
    expect(enterprise.logo.blob.byte_size).to eq 8974
    expect(enterprise.visible).to eq "public"
  end
end
