# frozen_string_literal: true

require 'rake'

RSpec.describe 'users.rake' do
  describe ':remove_enterprise_limit' do
    context 'when the user exists' do
      let(:user) { create(:user) }

      it 'sets the enterprise_limit to the maximum integer' do
        invoke_task "ofn:remove_enterprise_limit[#{user.id}]"

        expect(user.reload.enterprise_limit).to eq(2_147_483_647)
      end
    end

    context 'when the user does not exist' do
      it 'raises' do
        expect {
          invoke_task "ofn:remove_enterprise_limit[123]"
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
