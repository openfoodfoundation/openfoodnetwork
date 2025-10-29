# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::UserMailer do
  let(:user) { build(:user) }
  let(:order) { build(:order_with_totals_and_distribution) }

  before { ActionMailer::Base.deliveries.clear }

  describe '#signup_confirmation' do
    subject(:mail) { Spree::UserMailer.signup_confirmation(user) }

    it "sends email when given a user" do
      mail.deliver_now
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    context "user locale handling" do
      around do |example|
        original_default_locale = I18n.default_locale
        I18n.default_locale = 'pt'
        example.run
        I18n.default_locale = original_default_locale
      end

      it "sends email in user locale when user locale is defined" do
        user.locale = 'es'
        mail.deliver_now
        expect(ActionMailer::Base.deliveries.first.body).to include "Gracias por unirte"
      end

      it "sends email in default locale when user locale is not available" do
        user.locale = 'cn'
        mail.deliver_now
        expect(ActionMailer::Base.deliveries.first.body).to include "Obrigada por juntar-se"
      end
    end

    context "white labelling" do
      it_behaves_like 'email with inactive white labelling', :mail
      it_behaves_like 'non-customer facing email with active white labelling', :mail
    end
  end

  describe "#confirmation_instructions" do
    let(:token) { "random" }
    subject(:mail) { Spree::UserMailer.confirmation_instructions(user, token) }

    it "sends an email" do
      expect { mail.deliver_now }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    context 'when the language is English' do
      it 'sends an email with the translated subject' do
        mail.deliver_now
        expect(ActionMailer::Base.deliveries.first.subject).to include(
          "Please confirm your OFN account"
        )
      end
    end

    context 'when the language is Spanish' do
      let(:user) { build(:user, locale: 'es') }

      it 'sends an email with the translated subject' do
        mail.deliver_now
        expect(ActionMailer::Base.deliveries.first.subject).to include(
          "Por favor, confirma tu cuenta de OFN"
        )
      end
    end

    context "white labelling" do
      it_behaves_like 'email with inactive white labelling', :mail
      it_behaves_like 'non-customer facing email with active white labelling', :mail
    end
  end

  # adapted from https://github.com/spree/spree_auth_devise/blob/70737af/spec/mailers/user_mailer_spec.rb
  describe '#reset_password_instructions' do
    subject(:mail) { described_class.reset_password_instructions(user, nil).deliver_now }

    context "white labelling" do
      it_behaves_like 'email with inactive white labelling', :mail
      it_behaves_like 'non-customer facing email with active white labelling', :mail
    end

    describe 'message contents' do
      context 'subject includes' do
        it 'translated devise instructions' do
          expect(mail.subject).to include "Reset password instructions"
        end

        it 'Spree site name' do
          expect(mail.subject).to include Spree::Config[:site_name]
        end
      end

      context 'body includes' do
        it 'password reset url' do
          expect(mail.body).to include spree.edit_spree_user_password_url
        end
      end

      context 'when the language is Spanish' do
        let(:user) { build(:user, locale: 'es') }

        it 'calls with_locale method with user selected locale' do
          expect(I18n).to receive(:with_locale).with('es')
          mail
        end

        it 'calls devise reset_password_instructions subject' do
          expect(I18n).to receive(:t).with('spree.user_mailer.reset_password_instructions.subject')
          mail
        end
      end
    end

    describe 'legacy support for User object' do
      it 'sends an email' do
        expect do
          Spree::UserMailer.reset_password_instructions(user, nil).deliver_now
        end.to change { ActionMailer::Base.deliveries.size }.by(1)
      end
    end
  end
end
