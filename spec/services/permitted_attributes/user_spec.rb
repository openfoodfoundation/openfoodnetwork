# frozen_string_literal: true

require 'spec_helper'

module PermittedAttributes
  describe User do
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
