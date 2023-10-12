# frozen_string_literal: false

require 'spec_helper'

describe ReportBlob, type: :model do
  it "preserves UTF-8 content" do
    content = "This works. ✓"

    expect do
      blob = ReportBlob.create!("customers.html", content)
      content = blob.result
    end.to_not change { content.encoding }.from(Encoding::UTF_8)
  end
end
