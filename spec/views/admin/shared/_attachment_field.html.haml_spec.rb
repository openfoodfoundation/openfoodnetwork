# frozen_string_literal: true

RSpec.describe "admin/shared/_attachment_field.html.haml" do
  include FileHelper

  let(:enterprise) { create(:distributor_enterprise, white_label_logo: black_logo_file) }
  let(:f) { ActionView::Helpers::FormBuilder.new(:enterprise, enterprise, view, {}) }

  it "includes a preview of the image if one was already uploaded" do
    allow(view).to receive_messages(
      attachment_name: :white_label_logo,
      attachment_url: enterprise.white_label_logo_url,
      f:
    )

    render

    expect(rendered).to include("<img class=\"image-field-group__preview-image\"")
  end

  it "handles when a corrupt image was uploaded to S3 i.e. the file is present but a URL cannot be
      generated" do
    allow(view).to receive_messages(
      attachment_name: :white_label_logo,
      attachment_url: nil,
      f:
    )

    render

    expect(rendered).not_to include("<img class=\"image-field-group__preview-image\"")
  end
end
