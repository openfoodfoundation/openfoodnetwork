# frozen_string_literal: true

require_relative "../spec_helper"

# These tests depend on valid OpenID Connect client credentials in your
# `.env.test.local` file.
#
#     OPENID_APP_ID="..."
#     OPENID_APP_SECRET="..."
RSpec.describe DfcImporter do
  it "fetches a list of enterprises", :vcr do
    expect {
      subject.import_enterprise_profiles("lf-dev")
    }.to have_enqueued_mail(Spree::UserMailer, :confirmation_instructions)
      .and have_enqueued_mail(EnterpriseMailer, :welcome).twice

    # You can show the emails in your browser.
    # Consider creating a test helper if you find this useful elsewhere.
    # allow(ApplicationMailer).to receive(:delivery_method).and_return(:letter_opener)
    # perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob)
  end
end
