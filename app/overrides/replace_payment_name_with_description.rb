Deface::Override.new(:virtual_path => "spree/payments/_payment",
                     :replace      => "code[erb-loud]:contains('content_tag(:span, payment.payment_method.name)')",
                     :text         => "<%= content_tag( :span, ( payment.payment_method.description || payment.payment_method.name ).html_safe )  %>",
                     :name         => "replace_payment_name_with_description",
                     :original     => 'dff62efcadc0f9e6513b0f81a51ebbda035f78f6')
