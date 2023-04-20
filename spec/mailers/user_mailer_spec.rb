# frozen_string_literal: true

require 'spec_helper'

describe Spree::UserMailer do
  let(:user) { build(:user) }

  describe '#signup_confirmation' do
    it "sends email when given a user" do
      Spree::UserMailer.signup_confirmation(user).deliver_now
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    describe "user locale" do
      around do |example|
        original_default_locale = I18n.default_locale
        I18n.default_locale = 'pt'
        example.run
        I18n.default_locale = original_default_locale
      end

      it "sends email in user locale when user locale is defined" do
        user.locale = 'es'
        Spree::UserMailer.signup_confirmation(user).deliver_now
        expect(ActionMailer::Base.deliveries.first.body).to include "Gracias por unirte"
      end

      it "sends email in default locale when user locale is not available" do
        user.locale = 'cn'
        Spree::UserMailer.signup_confirmation(user).deliver_now
        expect(ActionMailer::Base.deliveries.first.body).to include "Obrigada por juntar-se"
      end
    end
  end

  describe "#confirmation_instructions" do
    it "sends an email" do
      token = "random"
      email = Spree::UserMailer.confirmation_instructions(user, token)

      expect {
        email.deliver_now
      }.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)
    end
  end

  # adapted from https://github.com/spree/spree_auth_devise/blob/70737af/spec/mailers/user_mailer_spec.rb
  describe '#reset_password_instructions' do
    describe 'message contents' do
      let(:message) { described_class.reset_password_instructions(user, nil).deliver_now }

      context 'subject includes' do
        it 'translated devise instructions' do
          expect(message.subject).to include "Reset password instructions"
        end

        it 'Spree site name' do
          expect(message.subject).to include Spree::Config[:site_name]
        end
      end

      context 'body includes' do
        it 'password reset url' do
          expect(message.body.raw_source).to include spree.edit_spree_user_password_url
        end
      end

      context 'when the language is Spanish' do
        let(:user) { build(:user, locale: 'es') }

        it 'calls with_locale method with user selected locale' do
          expect(I18n).to receive(:with_locale).with('es')
          message
        end

        it 'calls devise reset_password_instructions subject' do
          expect(I18n).to receive(:t).with('spree.user_mailer.reset_password_instructions.subject')
          message
        end
      end
    end

    describe 'legacy support for User object' do
      it 'sends an email' do
        expect do
          Spree::UserMailer.reset_password_instructions(user, nil).deliver_now
        end.to change(ActionMailer::Base.deliveries, :size).by(1)
      end
    end
  end
end
