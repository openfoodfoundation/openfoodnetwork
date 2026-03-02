# frozen_string_literal: false

RSpec.describe ReportBlob do
  it "preserves UTF-8 content" do
    content = "This works. ✓"

    expect do
      blob = ReportBlob.create_locally!("customers.html", content)
      content = blob.result
    end.not_to change { content.encoding }.from(Encoding::UTF_8)
  end

  it "can be created first and filled later" do
    blob = ReportBlob.create_for_upload_later!("customers.html")

    expect { blob.store("Hello") }
      .to change { blob.checksum }.from("0")
      .and change { blob.result }.from(nil).to("Hello")
  end
end
