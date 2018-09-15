class ApplicationController < ActionController::Base
  def not_found
    raise ActionController::RoutingError.new("Not Found")
  rescue
    render_404
  end

  def render_404
    render "shared/error", status: :not_found
  end
end
