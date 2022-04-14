# frozen_string_literal: true

require 'spec_helper'
require_relative '../../db/migrate/db/migrate/20220408093837_update_enterprise_social_links'

describe UpdateEnterpriseSocialLinks do
  subject { UpdateEnterpriseSocialLinks.new }

  let!(:enterprise1) { create(:enterprise, instagram: "https://www.instagram.com/happyfarm") }
  let!(:enterprise2) { create(:enterprise, instagram: "www.instagram.com/happyfarm") }
  let!(:enterprise3) { create(:enterprise, instagram: "@happyfarm") }
  let!(:enterprise4) { create(:enterprise, instagram: "happyfarm") }

  describe '#update_enterprise_social_links!' do
    subject.update_enterprise_social_links!
    context "when link includes https://www.instagram.com/" do
      it "removes https://www.instagram.com/" do
        expect(enterprise1.instagram).to eq("happyfarm")
      end
    end
    context "when link includes www.instagram.com/" do
      it "removes www.instagram.com/" do
        expect(enterprise2.instagram).to eq("happyfarm")
      end
    end
    context "when link includes @" do
      it "removes @" do
        expect(enterprise3.instagram).to eq("happyfarm")
      end
    end
    context "when link includes only the username" do
      it "does nothing" do
        expect(enterprise4.instagram).to eq("happyfarm")
      end
    end
  end
end
