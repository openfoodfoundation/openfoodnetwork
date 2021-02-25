# frozen_string_literal: true

shared_examples 'outstanding balance rendering' do
  context 'when the order has oustanding balance' do
    before { allow(order).to receive(:outstanding_balance?) { true } }

    it 'calls #display_outstanding_balance' do
      expect(order).to receive(:display_outstanding_balance) { '$123' }
      expect(email.body).to include('$123')
    end
  end

  context 'when the order has no outstanding balance' do
    before { allow(order).to receive(:outstanding_balance?) { false } }

    it 'does not call #display_outstanding_balance' do
      expect(order).not_to receive(:display_outstanding_balance)
      # calling #body triggers the Mail instance rendering
      email.body
    end

    it 'displays the payment status' do
      expect(email.body).to include(I18n.t(:email_payment_not_paid))
    end
  end
end

shared_examples 'outstanding balance view rendering' do
  context 'when the order has oustanding balance' do
    let(:user) { order.user }

    before { allow(order).to receive(:outstanding_balance?) { true } }

    it 'calls #display_outstanding_balance' do
      expect(order).to receive(:display_outstanding_balance) { '$123' }
      render
      expect(rendered).to include('$123')
    end
  end

  context 'when the order has no outstanding balance' do
    let(:user) { order.user }

    before { allow(order).to receive(:outstanding_balance?) { false } }

    it 'does not call #display_outstanding_balance' do
      expect(order).not_to receive(:display_outstanding_balance)
      render
    end

    it 'displays the payment status' do
      render
      expect(rendered).to include(I18n.t(:email_payment_not_paid))
    end
  end
end

shared_examples 'new outstanding balance rendering' do
  context 'when the order has oustanding balance' do
    before { allow(order).to receive(:new_outstanding_balance?) { true } }

    it 'calls #display_new_outstanding_balance' do
      expect(order).to receive(:display_new_outstanding_balance) { '$123' }
      expect(email.body).to include('$123')
    end
  end

  context 'when the order has no outstanding balance' do
    before { allow(order).to receive(:new_outstanding_balance?) { false } }

    it 'does not call #display_outstanding_balance' do
      expect(order).not_to receive(:display_new_outstanding_balance)
      # calling #body triggers the Mail instance rendering
      email.body
    end

    it 'displays the payment status' do
      expect(email.body).to include(I18n.t(:email_payment_not_paid))
    end
  end
end

shared_examples 'new outstanding balance view rendering' do
  context 'when the order has oustanding balance' do
    let(:user) { order.user }

    before { allow(order).to receive(:new_outstanding_balance?) { true } }

    it 'calls #display_new_outstanding_balance' do
      expect(order).to receive(:display_new_outstanding_balance) { '$123' }
      render
      expect(rendered).to include('$123')
    end
  end

  context 'when the order has no outstanding balance' do
    let(:user) { order.user }

    before { allow(order).to receive(:new_outstanding_balance?) { false } }

    it 'does not call #display_outstanding_balance' do
      expect(order).not_to receive(:display_new_outstanding_balance)
      render
    end

    it 'displays the payment status' do
      render
      expect(rendered).to include(I18n.t(:email_payment_not_paid))
    end
  end
end
