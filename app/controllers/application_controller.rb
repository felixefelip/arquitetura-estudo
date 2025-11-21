# rbs_inline: enabled

class ApplicationController < ActionController::Base
  # Protege contra CSRF attacks para formulários HTML
  protect_from_forgery with: :exception

  # @rbs!
  #   include _RbsRailsPathHelpers
  #   include ActionView::Helpers
  #
  #   def javascript_importmap_tags: () -> untyped
  #   def render: (*untyped) -> untyped
end
