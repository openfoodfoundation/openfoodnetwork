# frozen_string_literal: true

RSpec.describe "/admin/products/:product_id/images" do
  include AuthenticationHelper

  let!(:product) { create(:product) }

  before do
    login_as_admin
  end

  shared_examples "updating images" do |expected_http_status_code|
    let(:params) do
      {
        image: {
          attachment: fixture_file_upload("logo.png", "image/png"),
          viewable_id: product.id,
        }
      }
    end

    it "creates a new image and redirects unless called by turbo" do
      expect {
        subject
        product.reload
      }.to change{ product.image&.attachment&.filename.to_s }

      expect(response.status).to eq expected_http_status_code
      if expected_http_status_code == 302
        expect(response.location).to end_with spree.edit_admin_product_path(product)
      end

      expect(product.image.url(:product)).to end_with "logo.png"
    end
  end

  shared_context "with an invalid attachment" do
    let(:params) do
      {
        image: {
          attachment: fixture_file_upload("sample_file_120_products.csv", "text/csv"),
          viewable_id: product.id,
        }
      }
    end

    before do
      expect {
        subject
        product.reload
      }.not_to change{ product.image&.attachment&.filename.to_s }
    end
  end

  # Replacing an image renders the error on the image edit form it was submitted from.
  shared_examples "rejecting an invalid attachment in place" do
    include_context "with an invalid attachment"

    it "responds with an error" do
      expect(response.body).to include "Attachment has an invalid content type"
    end
  end

  # There is no HTML form for adding an image any more: the uploader lives on the
  # owner's edit page, so a failed upload goes back there as a flash.
  shared_examples "rejecting an invalid upload" do
    include_context "with an invalid attachment"

    it "redirects to the product's edit page with an error" do
      expect(response).to redirect_to spree.edit_admin_product_path(product)
      expect(flash[:error]).to include "Attachment has an invalid content type"
    end
  end

  describe "POST /admin/products/:product_id/images" do
    subject { post(spree.admin_product_images_path(product), params:) }

    it_behaves_like "updating images", 302
    it_behaves_like "rejecting an invalid upload"
  end

  describe "POST /admin/products/:product_id/images without a caption param" do
    let(:params) do
      {
        image: {
          attachment: fixture_file_upload("logo.png", "image/png"),
          viewable_id: product.id,
        }
      }
    end

    it "stores the product name as the caption" do
      post(spree.admin_product_images_path(product), params:)

      expect(product.reload.image.caption).to eq product.name
    end

    context "for a variant with a display name" do
      let(:variant) { create(:variant, product:, display_name: "Small bag") }
      let(:params) do
        {
          image: {
            attachment: fixture_file_upload("logo.png", "image/png"),
            viewable_id: variant.id,
          },
          variant_id: variant.id,
        }
      end

      it "stores the display name as the caption" do
        post(spree.admin_product_images_path(product), params:)

        expect(variant.reload.image.caption).to eq "Small bag"
      end
    end

    context "for a variant without a display name" do
      let(:variant) { create(:variant, product:, display_name: nil) }
      let(:params) do
        {
          image: {
            attachment: fixture_file_upload("logo.png", "image/png"),
            viewable_id: variant.id,
          },
          variant_id: variant.id,
        }
      end

      it "stores a blank caption rather than borrowing the product name" do
        post(spree.admin_product_images_path(product), params:)

        expect(variant.reload.image.caption).to eq ""
      end
    end
  end

  describe "POST /admin/products/:product_id/images with a caption param" do
    let(:params) do
      {
        image: {
          attachment: fixture_file_upload("logo.png", "image/png"),
          viewable_id: product.id,
          caption: "Fresh asparagus",
        }
      }
    end

    it "keeps the submitted caption instead of the default" do
      post(spree.admin_product_images_path(product), params:)

      expect(product.reload.image.caption).to eq "Fresh asparagus"
    end
  end

  describe "POST /admin/products/:product_id/images with turbo" do
    subject { post(spree.admin_product_images_path(product), params:, as: :turbo_stream) }

    it_behaves_like "updating images", 200
    it_behaves_like "rejecting an invalid attachment in place"
  end

  describe "POST /admin/products/:product_id/images with edit_after_upload" do
    let(:params) do
      {
        image: {
          attachment: fixture_file_upload("logo.png", "image/png"),
          viewable_id: product.id,
        },
        edit_after_upload: true,
      }
    end
    subject { post(spree.admin_product_images_path(product), params:, as: :turbo_stream) }

    it "creates the image and streams a redirect to its edit page" do
      expect {
        subject
        product.reload
      }.to change { product.image&.attachment&.filename.to_s }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq Mime[:turbo_stream]
      expect(response.body).to include 'action="redirect_to"'
      expect(response.body).to include(
        spree.edit_admin_product_image_path(product, product.image)
      )
    end

    context "with a wrong type of file" do
      let(:params) do
        {
          image: {
            attachment: fixture_file_upload("sample_file_120_products.csv", "text/csv"),
            viewable_id: product.id,
          },
          edit_after_upload: true,
        }
      end

      it "streams a flash error without creating an image" do
        post(spree.admin_product_images_path(product), params:, as: :turbo_stream)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(product.reload.image).not_to be_present
        expect(response.body).to include "flashes"
        expect(response.body).to include "Attachment has an invalid content type"
      end
    end
  end

  describe "POST /admin/products/:product_id/images for a variant with edit_after_upload" do
    let(:variant) { create(:variant, product:) }
    let(:params) do
      {
        image: {
          attachment: fixture_file_upload("logo.png", "image/png"),
          viewable_id: variant.id,
        },
        variant_id: variant.id,
        edit_after_upload: true,
      }
    end
    subject { post(spree.admin_product_images_path(product), params:, as: :turbo_stream) }

    it "creates the image on the variant and streams a redirect to its edit page" do
      expect {
        subject
        variant.reload
      }.to change { variant.image&.attachment&.filename.to_s }

      expect(variant.image.viewable_type).to eq "Spree::Variant"
      expect(variant.image.viewable_id).to eq variant.id
      expect(response.body).to include 'action="redirect_to"'
      expect(response.body).to include CGI.escapeHTML(
        spree.edit_admin_product_image_path(product, variant.image, variant_id: variant.id)
      )
    end
  end

  describe "PATCH /admin/products/:product_id/images/:id" do
    let!(:product) { create(:product_with_image) }
    subject {
      patch(spree.admin_product_image_path(product, product.image), params:)
    }

    it_behaves_like "updating images", 302

    context "with an invalid attachment" do
      include_context "with an invalid attachment"

      it "redirects to the image's edit page with the error in a flash" do
        expect(response).to redirect_to spree.edit_admin_product_image_path(
          product, product.image
        )
        expect(flash[:error]).to include "Attachment has an invalid content type"
      end
    end

    context "when attachment is not provided" do
      let(:params) do
        {
          image: {
            viewable_id: product.id,
            alt: "Updated alt text",
            caption: "Updated caption",
          }
        }
      end

      it "updates image metadata in place" do
        expect {
          subject
          product.reload
        }.not_to change { Spree::Image.count }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(spree.edit_admin_product_path(product))
        expect(product.image.alt).to eq("Updated alt text")
        expect(product.image.caption).to eq("Updated caption")
      end
    end

    context "when the caption is cleared" do
      let(:params) do
        {
          image: {
            viewable_id: product.id,
            caption: "",
          }
        }
      end

      it "stores the empty caption instead of keeping the previous one" do
        product.image.update!(caption: "Original caption")

        subject

        expect(product.reload.image.caption).to eq ""
      end
    end

    context "when replacing the image" do
      let(:params) do
        {
          image: {
            attachment: fixture_file_upload("thinking-cat.jpg", "image/jpeg"),
            viewable_id: product.id,
          }
        }
      end

      it "keeps an existing caption on the replacement" do
        product.image.update!(caption: "Original caption")

        expect { subject }.to change { product.reload.image.attachment&.filename.to_s }

        expect(product.reload.image.caption).to eq "Original caption"
      end

      context "when the caption is cleared while replacing the file" do
        let(:params) do
          {
            image: {
              attachment: fixture_file_upload("thinking-cat.jpg", "image/jpeg"),
              viewable_id: product.id,
              caption: "",
            }
          }
        end

        it "clears the caption on the replacement" do
          product.image.update!(caption: "Original caption")

          expect { subject }.to change { product.reload.image.attachment&.filename.to_s }

          expect(product.reload.image.caption).to eq ""
        end
      end
    end
  end

  describe "PATCH /admin/products/:product_id/images/:id with turbo" do
    let!(:product) { create(:product_with_image) }
    subject {
      patch(spree.admin_product_image_path(product, product.image), params:, as: :turbo_stream)
    }

    it_behaves_like "updating images", 200
    it_behaves_like "rejecting an invalid attachment in place"
  end

  describe "POST /admin/products/:product_id/images with variant_id" do
    let(:variant) { create(:variant, product:) }
    let(:params) do
      {
        image: {
          attachment: fixture_file_upload("logo.png", "image/png"),
          viewable_id: variant.id,
        },
        variant_id: variant.id,
      }
    end
    subject { post(spree.admin_product_images_path(product), params:) }

    it "creates a new image for the variant" do
      expect {
        subject
        variant.reload
      }.to change { variant.image&.attachment&.filename.to_s }

      expect(variant.image.viewable_type).to eq "Spree::Variant"
      expect(variant.image.viewable_id).to eq variant.id
    end

    it "redirects to the variant's edit page" do
      subject
      expect(response).to have_http_status :found
      expect(response.location)
        .to end_with spree.edit_admin_product_variant_path(product, variant)
    end

    context "with wrong type of file" do
      let(:params) do
        {
          image: {
            attachment: fixture_file_upload("sample_file_120_products.csv", "text/csv"),
            viewable_id: variant.id,
          },
          variant_id: variant.id,
        }
      end

      it "responds with an error" do
        expect {
          subject
          variant.reload
        }.not_to change { variant.image&.attachment&.filename.to_s }

        expect(response).to redirect_to spree.edit_admin_product_variant_path(product, variant)
        expect(flash[:error]).to include "Attachment has an invalid content type"
      end
    end
  end

  describe "GET /admin/products/:product_id/images/new" do
    subject { get(spree.new_admin_product_image_path(product)) }

    it "redirects to the product's edit page explaining where to upload" do
      subject

      expect(response).to redirect_to spree.edit_admin_product_path(product)
      expect(flash[:notice])
        .to eq "Please use the image uploader on this page to add an image."
    end

    context "with a variant_id" do
      let(:variant) { create(:variant, product:) }

      subject {
        get(spree.new_admin_product_image_path(product, variant_id: variant.id))
      }

      it "redirects to the variant's edit page" do
        subject

        expect(response).to redirect_to spree.edit_admin_product_variant_path(product, variant)
        expect(flash[:notice])
          .to eq "Please use the image uploader on this page to add an image."
      end
    end
  end

  describe "GET /admin/products/:product_id/images/:id/edit with an unknown image" do
    subject { get(spree.edit_admin_product_image_path(product, "unknown")) }

    it "flashes an error and redirects to the product's edit page" do
      subject

      expect(response).to redirect_to spree.edit_admin_product_path(product)
      expect(flash[:error]).to eq "Not found"
    end
  end

  describe "PATCH /admin/products/:product_id/images/:id with variant_id" do
    let(:variant) { create(:variant, product:) }
    let!(:variant_image) {
      Spree::Image.create!(
        attachment: fixture_file_upload("logo.png", "image/png"),
        viewable_id: variant.id,
        viewable_type: 'Spree::Variant'
      )
    }
    let(:params) do
      {
        image: {
          attachment: fixture_file_upload("thinking-cat.jpg", "image/jpeg"),
          viewable_id: variant.id,
        },
        variant_id: variant.id,
      }
    end
    subject {
      patch(spree.admin_product_image_path(product, variant_image), params:)
    }

    it "updates the variant image" do
      expect {
        subject
        variant.reload
      }.to change { variant.image&.attachment&.filename.to_s }

      expect(variant.image.viewable_type).to eq "Spree::Variant"
      expect(variant.image.viewable_id).to eq variant.id
    end

    it "redirects to the variant's edit page" do
      subject
      expect(response).to have_http_status :found
      expect(response.location)
        .to end_with spree.edit_admin_product_variant_path(product, variant)
    end

    context "with an invalid attachment" do
      let(:params) do
        {
          image: {
            attachment: fixture_file_upload("sample_file_120_products.csv", "text/csv"),
            viewable_id: variant.id,
          },
          variant_id: variant.id,
        }
      end

      it "redirects back to the image's edit page keeping the variant_id" do
        subject

        expect(response).to redirect_to spree.edit_admin_product_image_path(
          product, variant_image, variant_id: variant.id
        )
        expect(flash[:error]).to include "Attachment has an invalid content type"
      end
    end
  end

  # A blank viewable_id used to be trusted verbatim, saving an image that pointed at no
  # record at all (Spree::Asset doesn't require the polymorphic parent).
  describe "POST with a blank viewable_id" do
    let(:params) do
      {
        image: {
          attachment: fixture_file_upload("logo.png", "image/png"),
          viewable_id: "",
        }
      }
    end

    it "falls back to the product rather than creating an orphaned image" do
      expect { post(spree.admin_product_images_path(product), params:) }
        .to change { Spree::Image.count }.by(1)

      image = Spree::Image.last
      expect(image.viewable_type).to eq "Spree::Product"
      expect(image.viewable_id).to eq product.id
      expect(image.viewable).to eq product
    end

    context "when the parent is a variant" do
      let(:variant) { create(:variant, product:) }

      it "falls back to the variant" do
        expect {
          post(spree.admin_product_images_path(product, variant_id: variant.id), params:)
        }.to change { Spree::Image.count }.by(1)

        image = Spree::Image.last
        expect(image.viewable_type).to eq "Spree::Variant"
        expect(image.viewable_id).to eq variant.id
        expect(image.viewable).to eq variant
      end
    end
  end
end
