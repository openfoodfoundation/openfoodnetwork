# frozen_string_literal: true

RSpec.describe "layouts/registration.html.haml" do
  helper InjectionHelper
  helper I18nHelper
  helper ShopHelper

  before do
    allow(view).to receive_messages(
      current_order: nil,
      spree_current_user: nil
    )
  end

  it "displays language tags when there is more than one available locale" do
    render

    expect(rendered).to include('<link hreflang="en" href="http://test.host/locales/en">')
    expect(rendered).to include('<link hreflang="es" href="http://test.host/locales/es">')
    expect(rendered).to include('<link hreflang="pt" href="http://test.host/locales/pt">')
  end

  it "declares the page language" do
    I18n.with_locale(:en_AU) { render }

    expect(rendered).to include('<html lang="en-AU"')
  end

  it "starts Bugsnag before loading any JS bundle" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("BUGSNAG_JS_KEY").and_return("test-key")

    render

    first_bundle = rendered.index(%r{<script src="[^"]*/darkswarm/all})
    expect(rendered.index("Bugsnag.start")).to be < first_bundle
  end
end
