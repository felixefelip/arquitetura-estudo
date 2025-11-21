# frozen_string_literal: true

class HeaderComponent < ViewComponent::Base
  def initialize(usuario: nil, show_logout: false)
    @usuario = usuario
    @show_logout = show_logout
  end
end
