# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('db/migrate/20221208150521_update_enterprise_instagram_links.rb')

describe UpdateEnterpriseInstagramLinks do
  let!(:enterprise1) { create(:enterprise, instagram: "https://www.instagram.com/happyfarm") }

  let!(:enterprise2) { create(:enterprise, instagram: "@happyfarm") }

  let!(:enterprise3) { create(:enterprise, instagram: "happyfarm") }

  # rubocop:disable Style/NumericLiterals

  let(:current_version) { 20221208150521 }

  # rubocop:enable Style/NumericLiterals

  subject { ActiveRecord::Migrator.new(:up, migrations, current_version).migrate }

  context "when link includes https://www.instagram.com/" do
    it "removes https://www.instagram.com/" do
      expect(enterprise1.instagram).to eq("happyfarm")
    end
  end

  context "when link includes @" do
    it "removes @" do
      expect(enterprise2.instagram).to eq("happyfarm")
    end
  end

  context "when link includes only the username" do
    it "does nothing" do
      expect(enterprise3.instagram).to eq("happyfarm")
    end
  end
end
