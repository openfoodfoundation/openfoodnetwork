# frozen_string_literal: true

module Admin
  class ProductPreviewController < Spree::Admin::BaseController
    helper Admin::ProductsHelper

    def show
      @product = Spree::Product.find(params[:id])
      authorize! :show, @product

      respond_with do |format|
        format.turbo_stream {
          if product_pages?
            @product_view = product_view
            render "admin/products_v3/product_page_preview", status: :ok
          else
            render "admin/products_v3/product_preview", status: :ok
          end
        }
      end
    end

    private

    def model_class
      Spree::Product
    end

    # Shops with product pages show products on a page instead of in a modal, so the people
    # running those shops preview that page, whichever producer the product is from.
    def product_pages?
      OpenFoodNetwork::FeatureToggle.enabled?(
        "product-pages", spree_current_user, *spree_current_user.enterprises.is_distributor
      )
    end

    # The product as its page shows it. Without a shop and order cycle there are no
    # fees, and every variant is on offer.
    def product_view
      attrs = @product.slice(*ViewData::Product.members)
      attrs[:variants] = @product.variants
        .sort_by { |variant| [variant.name_to_display.to_s, variant.unit_value.to_f] }
        .map { |variant| variant_view(variant) }
      ViewData::Product.new(**attrs)
    end

    def variant_view(variant)
      presenter = VariantPresenter.new(variant:, with_fees: false)

      ViewData::Variant.new(
        **variant.slice(:id, :on_demand, :on_hand, :display_name, :name_to_display,
                        :unit_to_display, :price, :enterprise, :producer),
        price_with_fees: presenter.price_with_fees,
        display_price_with_fees: presenter.display_price_with_fees,
        unit_price: presenter.unit_price,
        display_unit_price: presenter.display_unit_price,
        fees: presenter.fee_breakdown,
        product: ViewData::SimpleProduct.new(id: @product.id, name: @product.name,
                                             group_buy: @product.group_buy)
      )
    end
  end
end
