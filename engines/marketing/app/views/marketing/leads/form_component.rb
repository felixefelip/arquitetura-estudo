# frozen_string_literal: true

class Marketing::Leads::FormComponent < ViewComponent::Base
  def initialize(plano:)
    @plano = plano
  end
end
