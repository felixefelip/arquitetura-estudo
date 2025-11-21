# frozen_string_literal: true

class Academico::Login::NewComponent < ViewComponent::Base
  def initialize(error_message: nil)
    @error_message = error_message
  end
end
