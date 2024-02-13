# frozen_string_literal: true

require 'spec_helper'

describe OidcAccount, type: :model do
  describe "associations and validations" do
    subject {
      OidcAccount.new(
        user: build(:user),
        provider: "openid_connect",
        uid: "user@example.net"
      )
    }

    it { is_expected.to belong_to :user }
    it { is_expected.to validate_uniqueness_of :uid }
  end
end
