# frozen_string_literal: true

class Academico::Login::FormComponent < ViewComponent::Base
  def initialize(error_message: nil)
    @error_message = error_message
  end
end
