# frozen_string_literal: true

require 'system_helper'

describe 'Multilingual' do
  include AuthenticationHelper
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper
  include CookieHelper

  it 'has three locales available' do
    expect(Rails.application.config.i18n[:default_locale]).to eq 'en'
    expect(Rails.application.config.i18n[:locale]).to eq 'en'
    expect(Rails.application.config.i18n[:available_locales]).to eq ['en', 'es', 'pt']
  end

  it '18n-js fallsback to default language' do
    # in backend it doesn't until we change enforce_available_locales to `true`
    visit root_path
    set_i18n_locale('it')
    expect(get_i18n_translation('label_shops')).to eq 'Shops'
  end

  context 'can switch language by params' do
    it 'in root path' do
      visit root_path
      expect(get_i18n_locale).to eq 'en'
      expect(get_i18n_translation('label_shops')).to eq 'Shops'
      expect(cookies).to be_empty
      expect(page).to have_content 'SHOPS'

      visit root_path(locale: 'es')
      expect(get_i18n_locale).to eq 'es'
      expect(get_i18n_translation('label_shops')).to eq 'Tiendas'
      expect_menu_and_cookie_in_es

      # it is not in the list of available of available_locales
      visit root_path(locale: 'it')
      expect(get_i18n_locale).to eq 'es'
      expect(get_i18n_translation('label_shops')).to eq 'Tiendas'
      expect_menu_and_cookie_in_es
    end

    context 'with a product in the cart' do
      let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
      let!(:order_cycle) {
        create(:simple_order_cycle, distributors: [distributor], variants: [product.variants.first])
      }
      let(:product) { create(:simple_product) }
      let(:order) { create(:order, order_cycle: order_cycle, distributor: distributor) }

      before do
        set_order order
        add_product_to_cart order, product, quantity: 1
      end

      it "in the cart page" do
        visit main_app.cart_path(locale: 'es')

        expect_menu_and_cookie_in_es
        expect(page).to have_content 'Precio'
      end

      it "in the checkout page" do
        visit checkout_path(locale: 'es')

        expect_menu_and_cookie_in_es
        expect(page).to have_content 'Total del carrito'
      end
    end
  end

  context 'with user' do
    let(:user) { create(:user) }

    it 'updates user locale from cookie if it is empty' do
      visit root_path(locale: 'es')

      expect_menu_and_cookie_in_es
      expect(user.locale).to be_nil
      login_as user
      visit root_path

      expect_menu_and_cookie_in_es
    end

    it 'updates user locale and stays in cookie after logout' do
      login_as user
      visit root_path(locale: 'es')
      user.reload

      expect(user.locale).to eq 'es'

      logout

      expect_menu_and_cookie_in_es
      expect(page).to have_content '¿Estás interesada en entrar en Open Food Network?'
    end
  end

  describe "using the language switcher UI" do
    before { browse_as_large }
    context "when there is only one language available" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("LOCALE").and_return("en")
        allow(ENV).to receive(:[]).with("AVAILABLE_LOCALES").and_return("en")
      end

      it "hides the dropdown language menu" do
        visit root_path
        expect(page).to have_no_css 'ul.right li.language-switcher.has-dropdown'
      end
    end

    context "when there are multiple languages available" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("LOCALE").and_return("en")
        allow(ENV).to receive(:[]).with("AVAILABLE_LOCALES").and_return("en,es")
      end

      it "allows switching language via the main navigation" do
        visit root_path

        expect(page).to have_content 'SHOPS'

        find('.language-switcher').click
        within '.language-switcher .dropdown' do
          expect(page).not_to have_link 'English', href: '/locales/en'
          expect(page).to have_link 'Español', href: '/locales/es'

          find('li a[href="/locales/es"]').click
        end

        expect_menu_and_cookie_in_es
      end
    end
  end
end

def expect_menu_and_cookie_in_es
  expect(cookies_name['locale']).to have_attributes(value: "es")
  expect(page).to have_content 'TIENDAS'
end
