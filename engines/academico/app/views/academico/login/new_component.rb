# frozen_string_literal: true

# rbs_inline: enabled

module Academico::Login
  class NewComponent < ViewComponent::Base
    # @rbs @error_message: String?

    #: (error_message: String?) -> void
    def initialize(error_message: nil)
      super()
      @error_message = error_message
    end
  end
end
