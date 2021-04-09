# frozen_string_literal: true

# Large requests can fail if Devise tries to store the URL in the session cookie.
#
# http://daniel.fone.net.nz/blog/2014/11/28/actiondispatch-cookies-cookieoverflow-via-devise-s-user_return_to/
require 'spec_helper'

RSpec.describe 'A very large request', type: :request do
  it 'should not overflow cookies' do
    get '/admin', params: { foo: 'x' * ActionDispatch::Cookies::MAX_COOKIE_SIZE }
    expect(response.status).to eq(302) # HTTP status 302 - Found
    ## Use the newer syntax if rspec gets upgraded
    # expect(response).to have_http_status(:redirect)
  end
end
