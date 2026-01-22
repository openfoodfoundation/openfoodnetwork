# frozen_string_literal: true


require_relative '../../db/migrate/20240502035220_update_n8n_url'

RSpec.describe UpdateN8nUrl do
  # We may want to move this to a support file if this syntax is useful in
  # other places. Reference:
  # - https://stackoverflow.com/a/34969429/3377535
  RSpec::Matchers.define_negated_matcher :not_change, :change

  let(:enterprise) { create(:enterprise) }
  let(:old_data) {
    {
      link: "https://link-to-form",
      destroy: "https://n8n.openfoodnetwork.org.uk/webhook/remove-enterprise?key=abc&id=123",
    }
  }
  let(:new_data) {
    {
      link: "https://link-to-form",
      destroy: "https://n8n.openfoodnetwork.org/webhook/remove-enterprise?key=abc&id=123",
    }
  }

  it "updates old connected app links" do
    app = ConnectedApp.create!(enterprise:, data: old_data,)

    expect {
      subject.up
      app.reload
    }.to change {
      app.data["destroy"]
    }.to("https://n8n.openfoodnetwork.org/webhook/remove-enterprise?key=abc&id=123")
      .and not_change {
        app.data["link"]
      }
  end

  it "keeps new connected app links" do
    app = ConnectedApp.create!(enterprise:, data: new_data,)

    expect {
      subject.up
      app.reload
    }.not_to change {
      app.data
    }
  end
end
