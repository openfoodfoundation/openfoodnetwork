require 'spec_helper'

describe Spree::Admin::ImageSettingsController do
  include AuthenticationHelper

  before { controller_login_as_admin }

  context "updating image settings" do
    it "should be able to update paperclip settings" do
      spree_put :update, preferences: { "attachment_path" => "foo/bar",
                                        "attachment_default_url" => "baz/bar" }

      expect(Spree::Config[:attachment_path]).to eq("foo/bar")
      expect(Spree::Config[:attachment_default_url]).to eq("baz/bar")
    end

    context "paperclip styles" do
      it "should be able to update the paperclip styles" do
        spree_put :update, "attachment_styles" => { "thumb" => "25x25>" }
        updated_styles = ActiveSupport::JSON.decode(Spree::Config[:attachment_styles])
        expect(updated_styles["thumb"]).to eq("25x25>")
      end

      it "should be able to add a new style" do
        spree_put :update, "attachment_styles" => {},
                           "new_attachment_styles" => { "1" => { "name" => "jumbo",
                                                                 "value" => "2000x2000>" } }
        styles = ActiveSupport::JSON.decode(Spree::Config[:attachment_styles])
        expect(styles["jumbo"]).to eq("2000x2000>")
      end
    end

    context "amazon s3" do
      after(:all) do
        Spree::Image.attachment_definitions[:attachment].delete :storage
      end

      it "should be able to update s3 settings" do
        spree_put :update, preferences:
        {
          "use_s3" => "1",
          "s3_access_key" => "a_valid_key",
          "s3_secret" => "a_secret",
          "s3_bucket" => "some_bucket"
        }
        expect(Spree::Config[:use_s3]).to be_truthy
        expect(Spree::Config[:s3_access_key]).to eq("a_valid_key")
        expect(Spree::Config[:s3_secret]).to     eq("a_secret")
        expect(Spree::Config[:s3_bucket]).to     eq("some_bucket")
      end

      context "headers" do
        before(:each) { Spree::Config[:use_s3] = true }

        it "should be able to update the s3 headers" do
          spree_put :update, "preferences" => { "use_s3" => "1" },
                             "s3_headers" => { "Cache-Control" => "max-age=1111" }
          headers = ActiveSupport::JSON.decode(Spree::Config[:s3_headers])
          expect(headers["Cache-Control"]).to eq("max-age=1111")
        end

        it "should be able to add a new header" do
          spree_put :update, "s3_headers" => {},
                             "new_s3_headers" => { "1" => { "name" => "Charset",
                                                            "value" => "utf-8" } }
          headers = ActiveSupport::JSON.decode(Spree::Config[:s3_headers])
          expect(headers["Charset"]).to eq("utf-8")
        end
      end
    end
  end
end
