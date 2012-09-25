Spree::CheckoutController.class_eval do
  #alias :edit :old_edit

  def edit
    if request.put?
      return self.update;
    end
  end

  def update
    @order.state = :address

    if @order.update_attributes(object_params)
      fire_event('spree.checkout.update')

      while @order.state != "complete" 
        if(!@order.next)
          flash[:error] = t(:payment_processing_failed)
          respond_with(@order, :location => checkout_state_path(@order.state))
          return
        end
        state_callback(:before)
        state_callback(:after)
      end

      if @order.state == "complete" || @order.completed?
        @order.finalize!
        flash.notice = t(:order_processed_successfully)
        flash[:commerce_tracking] = "nothing special"
        redirect_to(completion_route)
      else
        respond_with(@order, :location => checkout_state_path(@order.state))
      end
    else
      respond_with(@order) { |format| format.html { render :edit } }
    end
  end

  def load_order
    @order = current_order
    redirect_to cart_path and return unless @order and @order.checkout_allowed?
    raise_insufficient_quantity and return if @order.insufficient_stock_lines.present?
    #redirect_to cart_path and return if @order.completed?
    @order.state = params[:state] if params[:state]
    state_callback(:before)
  end
end

