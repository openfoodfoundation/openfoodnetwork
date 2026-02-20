# frozen_string_literal: true

RSpec.describe Spree::Core::MailSettings do
  context "overrides appplication defaults" do
    context "authentication method is login" do
      before do
        Spree::Config.mail_host = "smtp.example.com"
        Spree::Config.mail_domain = "example.com"
        Spree::Config.mail_port = 123
        Spree::Config.mail_auth_type = "login"
        Spree::Config.smtp_username = "schof"
        Spree::Config.smtp_password = "hellospree!"
        Spree::Config.secure_connection_type = "TLS"
        subject.override!
      end

      it { expect(ActionMailer::Base.smtp_settings[:address]).to eq "smtp.example.com" }
      it { expect(ActionMailer::Base.smtp_settings[:domain]).to eq "example.com" }
      it { expect(ActionMailer::Base.smtp_settings[:port]).to eq 123 }
      it { expect(ActionMailer::Base.smtp_settings[:authentication]).to eq "login" }
      it { expect(ActionMailer::Base.smtp_settings[:enable_starttls_auto]).to be_truthy }
      it { expect(ActionMailer::Base.smtp_settings[:user_name]).to eq "schof" }
      it { expect(ActionMailer::Base.smtp_settings[:password]).to eq "hellospree!" }
    end

    context "authentication method is none" do
      before do
        Spree::Config.mail_auth_type = "None"
        subject.override!
      end

      it "doesn't store 'None' as auth method" do
        expect(ActionMailer::Base.smtp_settings[:authentication]).to eq nil
      end
    end
  end
end
