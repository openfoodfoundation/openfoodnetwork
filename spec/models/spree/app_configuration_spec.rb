require 'spec_helper'

describe Spree::AppConfiguration do

  let (:prefs) { Rails.application.config.spree.preferences }

  it "should be available from the environment" do
    prefs.site_name = "TEST SITE NAME"
    prefs.site_name.should eq "TEST SITE NAME"
  end

  it "should be available as Spree::Config for legacy access" do
    Spree::Config.site_name = "Spree::Config TEST SITE NAME"
    Spree::Config.site_name.should eq "Spree::Config TEST SITE NAME"
  end

  it "uses base searcher class by default" do
    prefs.searcher_class = nil
    prefs.searcher_class.should eq Spree::Core::Search::Base
  end

  it 'uses Spree::Stock::Package by default' do
    prefs.package_factory = nil
    prefs.package_factory.should eq Spree::Stock::Package
  end

  context 'when a package factory is specified' do
    class TestPackageFactory; end

    around do |example|
      default_factory = prefs.package_factory
      example.run
      prefs.package_factory = default_factory
    end

    it 'uses the set package factory' do
      prefs.package_factory = TestPackageFactory
      prefs.package_factory.should eq TestPackageFactory
    end
  end

  it 'uses Spree::NullDecorator by default' do
    prefs.order_updater_decorator = nil
    prefs.order_updater_decorator.should eq Spree::NullDecorator
  end

  context 'when an order_updater_decorator is specified' do
    class FakeOrderUpdaterDecorator; end

    around do |example|
      default_decorator = prefs.order_updater_decorator
      example.run
      prefs.order_updater_decorator = default_decorator
    end

    it 'uses the set order_updater_decorator' do
      prefs.order_updater_decorator = FakeOrderUpdaterDecorator
      prefs.order_updater_decorator.should eq FakeOrderUpdaterDecorator
    end
  end
end
