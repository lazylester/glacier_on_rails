class ApplicationController < ActionController::Base
  protect_from_forgery
  before_action :check_permissions

  def check_permissions; end
end
