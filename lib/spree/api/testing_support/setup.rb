module Spree
  module Api
    module TestingSupport
      module Setup
        def sign_in_as_admin!
          let!(:current_api_user) do
            user = stub_model(Spree::LegacyUser)
            user.stub(:has_spree_role?).with("admin").and_return(true)

            # Stub enterprises, needed for cancan ability checks
            user.stub(:enterprises) { [] }

            user
          end
        end
      end
    end
  end
end
