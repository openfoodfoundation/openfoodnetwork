require 'spec_helper'

feature 'External services' do
  include AuthenticationWorkflow
  include WebHelper

  describe "bugherd" do
    describe "limiting inclusion by environment" do
      before { Spree::Config.bugherd_api_key = 'abc123' }

      it "is not included in test" do
        visit root_path
        expect(script_content(with: 'bugherd')).to be_nil
      end

      it "is not included in dev" do
        Rails.env.stub(:development?) { true }
        visit root_path
        expect(script_content(with: 'bugherd')).to be_nil
      end

      it "is included in staging" do
        Rails.env.stub(:staging?) { true }
        visit root_path
        expect(script_content(with: 'bugherd')).not_to be_nil
      end

      it "is included in production" do
        Rails.env.stub(:production?) { true }
        visit root_path
        expect(script_content(with: 'bugherd')).not_to be_nil
      end
    end

    context "in an environment where BugHerd is displayed" do
      before { Rails.env.stub(:staging?) { true } }

      context "when there is no API key set" do
        before { Spree::Config.bugherd_api_key = nil }

        it "does not include the BugHerd script" do
          visit root_path
          expect(script_content(with: 'bugherd')).to be_nil
        end
      end

      context "when an API key is set" do
        before { Spree::Config.bugherd_api_key = 'abc123' }

        it "includes the BugHerd script, with the correct API key" do
          visit root_path
          expect(script_content(with: 'bugherd')).to include 'abc123'
        end
      end
    end
  end
end
