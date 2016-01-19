module Spree
  module Api
    module TestingSupport
      module Setup
        def sign_in_as_user!
          let!(:current_api_user) do
            user = stub_model(Spree::LegacyUser)
            user.stub(:has_spree_role?).with("admin").and_return(false)
            user.stub(:enterprises) { [] }
            user.stub(:owned_groups) { [] }
            user
          end
        end

        # enterprises is an array of variable names of let defines
        # eg.
        # let(:enterprise) { ... }
        # sign_in_as_enterprise_user! [:enterprise]
        def sign_in_as_enterprise_user!(enterprises)
          let!(:current_api_user) do
            user = create(:user)
            user.spree_roles = []
            enterprises.each { |e| user.enterprise_roles.create(enterprise: send(e)) }
            user.save!
            user
          end
        end

        def sign_in_as_admin!
          let!(:current_api_user) do
            user = stub_model(Spree::LegacyUser)
            user.stub(:has_spree_role?).with("admin").and_return(true)

            # Stub enterprises, needed for cancan ability checks
            user.stub(:enterprises) { [] }
            user.stub(:owned_groups) { [] }

            user
          end
        end
      end
    end
  end
end
