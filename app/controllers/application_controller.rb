class ApplicationController < ActionController::Base
  def raise_not_found
    raise ActionController::RoutingError.new("Not Found")
  end
end
