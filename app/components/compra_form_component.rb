# frozen_string_literal: true

class CompraFormComponent < ViewComponent::Base
  def initialize(plano:)
    @plano = plano
  end
end
