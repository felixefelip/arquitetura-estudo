# frozen_string_literal: true

# rbs_inline: enabled

class Shared::HeaderComponent < ViewComponent::Base
  # @rbs @usuario: untyped
  # @rbs @show_logout: bool

  #: (?usuario: untyped, ?show_logout: bool) -> void
  def initialize(usuario: nil, show_logout: false)
    @usuario = usuario
    @show_logout = show_logout
  end
end
