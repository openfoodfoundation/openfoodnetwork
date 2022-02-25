# frozen_string_literal: true

require "spec_helper"

describe "layouts/darkswarm.html.haml" do
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
end
