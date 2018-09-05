module Api
  class CookiesConsentController < BaseController
    include ActionController::Cookies
    respond_to :json

    def show
      render json: { cookies_consent: cookies_consent.exists? }
    end

    def create
      cookies_consent.set
      show
    end

    def destroy
      cookies_consent.destroy
      show
    end

    private

    def cookies_consent
      @cookies_consent ||= CookiesConsent.new(cookies, request.host)
    end
  end
end
