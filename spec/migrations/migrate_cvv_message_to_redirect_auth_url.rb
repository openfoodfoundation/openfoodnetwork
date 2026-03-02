# frozen_string_literal: true

require_relative '../../db/migrate/20250827205335_migrate_cvv_message_to_redirect_auth_url'

RSpec.describe MigrateCvvMessageToRedirectAuthUrl, type: :migration do
  let(:migration) { described_class.new }

  describe '#up' do
    context 'when payments have cvv_response_message with redirect URLs and are not completed' do
      let!(:payment_requires_auth) do
        create(:payment,
               cvv_response_message: 'https://bank.com/3ds-redirect?token=abc123',
               redirect_auth_url: nil,
               state: 'requires_authorization')
      end

      let!(:payment_processing) do
        create(:payment,
               cvv_response_message: 'https://payment-gateway.com/auth/redirect',
               redirect_auth_url: nil,
               state: 'processing')
      end

      let!(:payment_pending) do
        create(:payment,
               cvv_response_message: 'https://secure.payment.com/authenticate',
               redirect_auth_url: nil,
               state: 'pending')
      end

      it 'migrates cvv_response_message to redirect_auth_url' do
        migration.up

        payment_requires_auth.reload
        payment_processing.reload
        payment_pending.reload

        expect(payment_requires_auth.redirect_auth_url).to eq('https://bank.com/3ds-redirect?token=abc123')
        expect(payment_processing.redirect_auth_url).to eq('https://payment-gateway.com/auth/redirect')
        expect(payment_pending.redirect_auth_url).to eq('https://secure.payment.com/authenticate')

        expect(payment_requires_auth.cvv_response_message).to be_nil
        expect(payment_processing.cvv_response_message).to be_nil
        expect(payment_pending.cvv_response_message).to be_nil
      end
    end

    context 'when payments are completed' do
      let!(:completed_payment) do
        create(:payment,
               cvv_response_message: nil,
               redirect_auth_url: nil,
               state: 'completed')
      end

      it 'does not affect completed payments (they already have nil cvv_response_message)' do
        migration.up

        completed_payment.reload

        expect(completed_payment.cvv_response_message).to be_nil
        expect(completed_payment.redirect_auth_url).to be_nil
      end
    end

    context 'when payments have nil cvv_response_message' do
      let!(:nil_cvv_payment) do
        create(:payment,
               cvv_response_message: nil,
               redirect_auth_url: nil,
               state: 'pending')
      end

      it 'does not migrate payments with nil cvv_response_message' do
        migration.up

        nil_cvv_payment.reload

        expect(nil_cvv_payment.cvv_response_message).to be_nil
        expect(nil_cvv_payment.redirect_auth_url).to be_nil
      end
    end

    context 'mixed payment states' do
      let!(:eligible_payments) do
        [
          create(
            :payment,
            cvv_response_message: 'https://url1.com',
            state: 'requires_authorization'
          ),
          create(:payment, cvv_response_message: 'https://url2.com', state: 'processing'),
          create(:payment, cvv_response_message: 'https://url3.com', state: 'pending'),
          create(:payment, cvv_response_message: 'https://url4.com', state: 'checkout'),
          create(:payment, cvv_response_message: 'https://url5.com', state: 'failed'),
          create(:payment, cvv_response_message: 'https://url6.com', state: 'void'),
          create(:payment, cvv_response_message: 'https://url7.com', state: 'invalid')
        ]
      end

      let!(:ineligible_payments) do
        [
          create(:payment, cvv_response_message: nil, state: 'completed'),
          create(:payment, cvv_response_message: nil, state: 'requires_authorization')
        ]
      end

      it 'only migrates non-completed payments with cvv_response_message' do
        migration.up

        # Check eligible payments were migrated
        eligible_payments.each do |payment|
          payment.reload
          expect(payment.redirect_auth_url).to be_present
          expect(payment.cvv_response_message).to be_nil
        end

        # Check ineligible payments were not migrated
        ineligible_payments.each do |payment|
          payment.reload
          expect(payment.redirect_auth_url).to be_nil
          expect(payment.cvv_response_message).to be_nil
        end
      end
    end
  end

  describe '#down' do
    context 'when payments have redirect_auth_url and are not completed' do
      let!(:requires_auth_payment) do
        create(:payment,
               cvv_response_message: nil,
               redirect_auth_url: 'https://bank.com/3ds-redirect?token=xyz789',
               state: 'requires_authorization')
      end

      let!(:processing_payment_with_redirect) do
        create(:payment,
               cvv_response_message: nil,
               redirect_auth_url: 'https://gateway.com/authenticate',
               state: 'processing')
      end

      it 'migrates redirect_auth_url back to cvv_response_message' do
        migration.down

        requires_auth_payment.reload
        processing_payment_with_redirect.reload

        expect(requires_auth_payment.cvv_response_message).to eq('https://bank.com/3ds-redirect?token=xyz789')
        expect(processing_payment_with_redirect.cvv_response_message).to eq('https://gateway.com/authenticate')
        expect(requires_auth_payment.redirect_auth_url).to be_nil
        expect(processing_payment_with_redirect.redirect_auth_url).to be_nil
      end
    end

    context 'when payments are completed' do
      let!(:completed_payment_with_redirect) do
        create(:payment,
               cvv_response_message: nil,
               redirect_auth_url: nil,
               state: 'completed')
      end

      it 'does not affect completed payments (they have nil values)' do
        migration.down

        completed_payment_with_redirect.reload

        expect(completed_payment_with_redirect.redirect_auth_url).to be_nil
        expect(completed_payment_with_redirect.cvv_response_message).to be_nil
      end
    end

    context 'when payments have nil redirect_auth_url' do
      let!(:nil_redirect_payment) do
        create(:payment,
               cvv_response_message: nil,
               redirect_auth_url: nil,
               state: 'pending')
      end

      it 'does not affect payments with nil redirect_auth_url' do
        migration.down

        nil_redirect_payment.reload

        expect(nil_redirect_payment.redirect_auth_url).to be_nil
        expect(nil_redirect_payment.cvv_response_message).to be_nil
      end
    end
  end

  describe 'full migration cycle (up then down)' do
    let!(:original_payments) do
      [
        create(
          :payment,
          cvv_response_message: 'https://original1.com/auth',
          state: 'requires_authorization'
        ),
        create(
          :payment,
          cvv_response_message: 'https://original2.com/redirect',
          state: 'processing'
        ),
        create(
          :payment,
          cvv_response_message: 'https://original3.com/3ds',
          state: 'pending'
        )
      ]
    end

    it 'preserves data integrity through up and down migrations' do
      original_urls = original_payments.map(&:cvv_response_message)

      # Verify initial state
      expect(original_payments.all? { |p| p.redirect_auth_url.nil? }).to be true

      # Migrate up
      migration.up
      original_payments.each(&:reload)

      # Verify up migration
      expect(original_payments.map(&:redirect_auth_url)).to eq(original_urls)
      expect(original_payments.all? { |p| p.cvv_response_message.nil? }).to be true

      # Migrate down
      migration.down
      original_payments.each(&:reload)

      # Verify down migration restores original state
      expect(original_payments.map(&:cvv_response_message)).to eq(original_urls)
      expect(original_payments.all? { |p| p.redirect_auth_url.nil? }).to be true
    end
  end
end
