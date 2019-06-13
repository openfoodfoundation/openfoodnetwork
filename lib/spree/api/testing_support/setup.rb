module Spree
  module Api
    module TestingSupport
      module Setup
        def sign_in_as_user!
          let!(:current_api_user) do
            user = Spree::LegacyUser.new(email: "spree@example.com")
            user.stub(:has_spree_role?).with("admin").and_return(false)
            user.stub(:enterprises) { [] }
            user.stub(:owned_groups) { [] }
            user.stub(:spree_api_key) { "spree_api_key" }
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
            enterprises.each do |enterprise|
              user.enterprise_roles.create(enterprise: public_send(enterprise))
            end
            user.save!
            user
          end
        end

        def sign_in_as_admin!
          let!(:current_api_user) do
            user = Spree::LegacyUser.new(email: "spree@example.com")
            user.stub(:has_spree_role?).with("admin").and_return(true)

            # Stub enterprises, needed for cancan ability checks
            user.stub(:enterprises) { [] }
            user.stub(:owned_groups) { [] }

            user.stub(:spree_api_key) { "admin_spree_api_key" }
            user
          end
        end
      end
    end
  end
end
