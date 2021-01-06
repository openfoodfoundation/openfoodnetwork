# Fixes the issue about some PayPal requests failing with
# OpenSSL::SSL::SSLError (SSL_connect returned=1 errno=0 state=error: certificate verify failed)
module CAFileHack
  # This overrides paypal-sdk-core default so we don't pass the cert the gem provides to the
  # NET::HTTP instance. This way we rely on the default behavior of validating the server's cert
  # against the CA certs of the OS (we assume), which tend to be up to date.
  #
  # See https://github.com/openfoodfoundation/openfoodnetwork/issues/5855 for details.
  def default_ca_file
    nil
  end
end

require 'paypal-sdk-merchant'
PayPal::SDK::Core::Util::HTTPHelper.prepend(CAFileHack)
