# frozen_string_literal: true

class LoginFormComponent < ViewComponent::Base
  def initialize(error_message: nil)
    @error_message = error_message
  end
end
