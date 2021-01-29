# frozen_string_literal: true

require 'spec_helper'

module Spree
  module Core
    describe MailSettings do
      let!(:subject) { MailSettings.new }

      context "overrides appplication defaults" do
        context "authentication method is none" do
          before do
            Config.mail_host = "smtp.example.com"
            Config.mail_domain = "example.com"
            Config.mail_port = 123
            Config.mail_auth_type = MailSettings::SECURE_CONNECTION_TYPES[0]
            Config.smtp_username = "schof"
            Config.smtp_password = "hellospree!"
            Config.secure_connection_type = "TLS"
            subject.override!
          end

          it { expect(ActionMailer::Base.smtp_settings[:address]).to eq "smtp.example.com" }
          it { expect(ActionMailer::Base.smtp_settings[:domain]).to eq "example.com" }
          it { expect(ActionMailer::Base.smtp_settings[:port]).to eq 123 }
          it { expect(ActionMailer::Base.smtp_settings[:authentication]).to eq "None" }
          it { expect(ActionMailer::Base.smtp_settings[:enable_starttls_auto]).to be_truthy }

          it "doesnt touch user name config" do
            expect(ActionMailer::Base.smtp_settings[:user_name]).to be_nil
          end

          it "doesnt touch password config" do
            expect(ActionMailer::Base.smtp_settings[:password]).to be_nil
          end
        end
      end

      context "when mail_auth_type is other than none" do
        before do
          Config.mail_auth_type = "login"
          Config.smtp_username = "schof"
          Config.smtp_password = "hellospree!"
          subject.override!
        end

        context "overrides user credentials" do
          it { expect(ActionMailer::Base.smtp_settings[:user_name]).to eq "schof" }
          it { expect(ActionMailer::Base.smtp_settings[:password]).to eq "hellospree!" }
        end
      end
    end
  end
end
