# frozen_string_literal: true

module PermittedAttributes
  RSpec.describe User do
    describe "simple usage" do
      let(:user_permitted_attributes) { PermittedAttributes::User.new(params) }

      describe "permits basic attributes" do
        let(:params) {
          ActionController::Parameters.new(user: { name: "John",
                                                   email: "email@example.com" } )
        }

        it "keeps permitted and removes not permitted" do
          permitted_attributes = user_permitted_attributes.call

          expect(permitted_attributes[:name]).to be nil
          expect(permitted_attributes[:email]).to eq "email@example.com"
        end

        it "keeps extra permitted attributes" do
          permitted_attributes = user_permitted_attributes.call([:name])

          expect(permitted_attributes[:name]).to eq "John"
          expect(permitted_attributes[:email]).to eq "email@example.com"
        end
      end
    end

    describe "disabled attribute" do
      let(:params) {
        ActionController::Parameters.new(user: { disabled: "1" })
      }

      it "does not permit disabling a user by default" do
        permitted_attributes = PermittedAttributes::User.new(params).call

        expect(permitted_attributes[:disabled]).to be_nil
      end

      it "permits disabling a user when explicitly allowed" do
        permitted_attributes = PermittedAttributes::User.new(params).call([:disabled])

        expect(permitted_attributes[:disabled]).to eq "1"
      end
    end

    describe "with custom resource_name" do
      let(:user_permitted_attributes) { PermittedAttributes::User.new(params, :spree_user) }
      let(:params) {
        ActionController::Parameters.new(spree_user: { name: "John",
                                                       email: "email@example.com" } )
      }

      it "keeps permitted and removes not permitted" do
        permitted_attributes = user_permitted_attributes.call

        expect(permitted_attributes[:name]).to be nil
        expect(permitted_attributes[:email]).to eq "email@example.com"
      end
    end
  end
end
