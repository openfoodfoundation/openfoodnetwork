require 'spec_helper'

feature "Using embedded shopfront functionality", js: true do
  include OpenFoodNetwork::EmbeddedPagesHelper

  describe 'embedded groups' do
    let(:enterprise) { create(:distributor_enterprise) }
    let(:group) { create(:enterprise_group, enterprises: [enterprise]) }

    before do
      Spree::Config[:enable_embedded_shopfronts] = true
      Spree::Config[:embedded_shopfronts_whitelist] = 'test.com'
      allow_any_instance_of(ActionDispatch::Request).to receive(:referer).and_return('https://www.test.com')
      visit "/embedded-group-preview.html?#{group.permalink}"
    end

    it "displays in an iframe" do
      on_embedded_page do
        within 'div#group-page' do
          expect(page).to have_content 'About Us'
        end
      end
    end

    it "displays powered by OFN text at bottom of page" do
      on_embedded_page do
        within 'div#group-page' do
          expect(page).to have_selector 'div.powered-by-embedded'
          expect(page).to have_css "img[src*='favicon.ico']"
          expect(page).to have_content 'Powered by'
          expect(page).to have_content 'Open Food Network'
        end
      end
    end

    it "doesn't display contact details when embedded" do
      on_embedded_page do
        within 'div#group-page' do

          expect(page).to have_no_selector 'div.contact-container'
          expect(page).to have_no_content '#{group.address.address1}'
        end
      end
    end

    it "does not display the header when embedded" do
      on_embedded_page do
        within 'div#group-page' do
          expect(page).to have_no_selector 'header'
          expect(page).to have_no_selector 'img.group-logo'
          expect(page).to have_no_selector 'h2.group-name'
        end
      end
    end

    it "opens links to shops in a new window" do
      on_embedded_page do
        within 'div#group-page' do
          shop_links_xpath = "//*[contains(@href, '#{enterprise.permalink}/shop')]"

          expect(page).to have_xpath shop_links_xpath, visible: false

          shop_links = page.all(:xpath, shop_links_xpath, visible: false)
          shop_links.each do |link|
            expect(link[:target]).to eq "_blank"
          end
        end
      end
    end
  end
end
