# frozen_string_literal: true

class Marketing::Leads::NewComponent < ViewComponent::Base
  def initialize(plano:)
    @plano = plano
  end
end
