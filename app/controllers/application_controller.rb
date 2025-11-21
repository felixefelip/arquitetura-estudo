class ApplicationController < ActionController::Base
  # Protege contra CSRF attacks para formulários HTML
  protect_from_forgery with: :exception
end
