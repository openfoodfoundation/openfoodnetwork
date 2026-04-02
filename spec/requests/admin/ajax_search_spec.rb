# frozen_string_literal: true

RSpec.describe "/admin/ajax_search" do
  include AuthenticationHelper

  let(:admin_user) { create(:admin_user) }
  let(:regular_user) { create(:user) }

  describe "GET /admin/ajax_search/producers" do
    context "when user is not logged in" do
      it "redirects to login" do
        get admin_ajax_search_producers_path

        expect(response).to redirect_to %r|#/login$|
      end
    end

    context "when user is logged in without permissions" do
      before { login_as regular_user }

      it "redirects to unauthorized" do
        get admin_ajax_search_producers_path

        expect(response).to redirect_to('/unauthorized')
      end
    end

    context "when user is an admin" do
      before { login_as admin_user }

      let!(:producer1) { create(:supplier_enterprise, name: "Apple Farm") }
      let!(:producer2) { create(:supplier_enterprise, name: "Berry Farm") }
      let!(:producer3) { create(:supplier_enterprise, name: "Cherry Orchard") }
      let!(:distributor) { create(:distributor_enterprise, name: "Distributor") }

      it "returns producers sorted alphabetically by name" do
        get admin_ajax_search_producers_path

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response["results"].pluck("label")).to eq(['Apple Farm', 'Berry Farm',
                                                               'Cherry Orchard'])
        expect(json_response["pagination"]["more"]).to be false
      end

      it "filters producers by search query" do
        get admin_ajax_search_producers_path, params: { q: "berry" }

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(['Berry Farm'])
        expect(json_response["results"].pluck("value")).to eq([producer2.id])
      end

      it "filters are case insensitive" do
        get admin_ajax_search_producers_path, params: { q: "BERRY" }

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(['Berry Farm'])
      end

      it "filters with partial matches" do
        get admin_ajax_search_producers_path, params: { q: "Farm" }

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(['Apple Farm', 'Berry Farm'])
      end

      it "excludes non-producer enterprises" do
        get admin_ajax_search_producers_path

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).not_to include('Distributor')
      end

      context "with more than 30 producers" do
        before do
          create_list(:supplier_enterprise, 35) do |enterprise, i|
            enterprise.update!(name: "Producer #{(i + 1).to_s.rjust(2, '0')}")
          end
        end

        it "returns first page with 30 results and more flag as true" do
          get admin_ajax_search_producers_path, params: { page: 1 }

          json_response = response.parsed_body
          expect(json_response["results"].length).to eq(30)
          expect(json_response["pagination"]["more"]).to be true
        end

        it "returns remaining results on second page with more flag as false" do
          get admin_ajax_search_producers_path, params: { page: 2 }

          json_response = response.parsed_body
          expect(json_response["results"].length).to eq(8)
          expect(json_response["pagination"]["more"]).to be false
        end
      end
    end

    context "when user has enterprise permissions" do
      let!(:my_producer) { create(:supplier_enterprise, name: "My Producer") }
      let!(:other_producer) { create(:supplier_enterprise, name: "Other Producer") }
      let(:user_with_producer) { create(:user, enterprises: [my_producer]) }

      before { login_as user_with_producer }

      it "returns only managed producers" do
        get admin_ajax_search_producers_path

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(['My Producer'])
        expect(json_response["results"].pluck("label")).not_to include('Other Producer')
      end
    end
  end

  describe "GET /admin/ajax_search/categories" do
    context "when user is not logged in" do
      it "redirects to login" do
        get admin_ajax_search_categories_path

        expect(response).to redirect_to %r|#/login$|
      end
    end

    context "when user is logged in without permissions" do
      before { login_as regular_user }

      it "redirects to unauthorized" do
        get admin_ajax_search_categories_path

        expect(response).to redirect_to('/unauthorized')
      end
    end

    context "when user is an admin" do
      before { login_as admin_user }

      let!(:category1) { create(:taxon, name: "Vegetables") }
      let!(:category2) { create(:taxon, name: "Fruits") }
      let!(:category3) { create(:taxon, name: "Dairy") }

      it "returns categories sorted alphabetically by name" do
        get admin_ajax_search_categories_path

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response["results"].pluck("label")).to eq(['Dairy', 'Fruits', 'Vegetables'])
        expect(json_response["pagination"]["more"]).to be false
      end

      it "filters categories by search query" do
        get admin_ajax_search_categories_path, params: { q: "fruit" }

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(['Fruits'])
        expect(json_response["results"].pluck("value")).to eq([category2.id])
      end

      it "filters are case insensitive" do
        get admin_ajax_search_categories_path, params: { q: "VEGETABLES" }

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(['Vegetables'])
      end

      it "filters with partial matches" do
        get admin_ajax_search_categories_path, params: { q: "ege" }

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(['Vegetables'])
      end

      context "with more than 30 categories" do
        before do
          create_list(:taxon, 35) do |taxon, i|
            taxon.update!(name: "Category #{(i + 1).to_s.rjust(2, '0')}")
          end
        end

        it "returns first page with 30 results and more flag as true" do
          get admin_ajax_search_categories_path, params: { page: 1 }

          json_response = response.parsed_body
          expect(json_response["results"].length).to eq(30)
          expect(json_response["pagination"]["more"]).to be true
        end

        it "returns remaining results on second page with more flag as false" do
          get admin_ajax_search_categories_path, params: { page: 2 }

          json_response = response.parsed_body
          expect(json_response["results"].length).to eq(8)
          expect(json_response["pagination"]["more"]).to be false
        end
      end
    end
  end

  describe "GET /admin/ajax_search/tax_categories" do
    context "when user is not logged in" do
      it "redirects to login" do
        get admin_ajax_search_tax_categories_path

        expect(response).to redirect_to %r|#/login$|
      end
    end

    context "when user is logged in without permissions" do
      before { login_as regular_user }

      it "redirects to unauthorized" do
        get admin_ajax_search_tax_categories_path

        expect(response).to redirect_to('/unauthorized')
      end
    end

    context "when user is an admin" do
      before { login_as admin_user }

      let!(:tax_cat1) { create(:tax_category, name: "GST") }
      let!(:tax_cat2) { create(:tax_category, name: "VAT") }
      let!(:tax_cat3) { create(:tax_category, name: "No Tax") }

      it "returns tax categories sorted alphabetically by name" do
        get admin_ajax_search_tax_categories_path

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response["results"].pluck("label")).to eq(['GST', 'No Tax', 'VAT'])
        expect(json_response["pagination"]["more"]).to be false
      end

      it "filters tax categories by search query" do
        get admin_ajax_search_tax_categories_path, params: { q: "vat" }

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(['VAT'])
        expect(json_response["results"].pluck("value")).to eq([tax_cat2.id])
      end

      it "filters are case insensitive" do
        get admin_ajax_search_tax_categories_path, params: { q: "GST" }

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(['GST'])
      end

      it "filters with partial matches" do
        get admin_ajax_search_tax_categories_path, params: { q: "tax" }

        json_response = response.parsed_body
        expect(json_response["results"].pluck("label")).to eq(['No Tax'])
      end

      context "with more than 30 tax categories" do
        before do
          create_list(:tax_category, 35) do |tax_cat, i|
            tax_cat.update!(name: "Tax Category #{(i + 1).to_s.rjust(2, '0')}")
          end
        end

        it "returns first page with 30 results and more flag as true" do
          get admin_ajax_search_tax_categories_path, params: { page: 1 }

          json_response = response.parsed_body
          expect(json_response["results"].length).to eq(30)
          expect(json_response["pagination"]["more"]).to be true
        end

        it "returns remaining results on second page with more flag as false" do
          get admin_ajax_search_tax_categories_path, params: { page: 2 }

          json_response = response.parsed_body
          expect(json_response["results"].length).to eq(8)
          expect(json_response["pagination"]["more"]).to be false
        end
      end
    end
  end
end
