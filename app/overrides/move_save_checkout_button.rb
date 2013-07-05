=begin
# Add a new 'Save and Continue/Process My Order' button under Order Summary on the checkout pages
Deface::Override.new(:virtual_path  => "spree/checkout/edit",
                     :insert_after  => "[data-hook='checkout_summary_box']",
                     :text          => '<div id="add_new_save_checkout_button" class="columns omega four" 
                                            style="display:none; margin-top: 30px; padding-top:10px; border-top: 1px solid #d9d9db;">
                                          <%= submit_tag @order.state == "payment" ? "Process My Order" : t(:save_and_continue), 
                                                          :class => "continue button primary large", 
                                                          :form=> "checkout_form_#{@order.state}" %>
                                          <script>
                                            disableSaveOnClick();
                                            //Show additional button only if form attribute is supported
                                            if ($("#add_new_save_checkout_button input[type=submit]")[0].form)
                                              $("#add_new_save_checkout_button").show();
                                          </script>
                                        </div>',
                     :name          => "add_new_save_checkout_button",
                     :disabled      => true)
 =end
                     
# Remove the old button from each partial
=begin
Deface::Override.new(:virtual_path  => "spree/checkout/_address",
                     :remove        => "[data-hook='buttons']",
                     :name          => "remove_save_checkout_button",
                     :original      => '7633572669c527863fea8033e487babd2373ec09')
                     
Deface::Override.new(:virtual_path  => "spree/checkout/_delivery",
                     :remove        => "[data-hook='buttons']",
                     :name          => "remove_save_checkout_button",
                     :original      => '7633572669c527863fea8033e487babd2373ec09')
                     
Deface::Override.new(:virtual_path  => "spree/checkout/_payment",
                     :remove        => "[data-hook='buttons']",
                     :name          => "remove_save_checkout_button",
                     :original      => '312bd1fc045d5bde88f37b41b89ff3ca08beb950')
=end

#Hide 
=begin
Deface::Override.new(:virtual_path  => "spree/checkout/edit",
                     :insert_after  => "#checkout",
                     :text          => '<script type="text/javascript">
                                          if (!$("#add_new_save_checkout_button input[type=submit]")[0].form)
                                          {
                                            $("#add_new_save_checkout_button").hide();
                                          }
                                        </script>',
                     :name          => "hide_new_save_checkout_button")
=end