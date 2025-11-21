# rbs_inline: enabled

class ApplicationController < ActionController::Base
  # Protege contra CSRF attacks para formulários HTML
  protect_from_forgery with: :exception

  # @rbs!
  #    include _RbsRailsPathHelpers
end
