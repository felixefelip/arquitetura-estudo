# rbs_inline: enabled

module Marketing::Leads
  class FormComponent < ViewComponent::Base
    # @rbs @plano: Hash[Symbol, untyped]

    #: (plano: Hash[Symbol, untyped]) -> void
    def initialize(plano:)
      super
      @plano = plano
    end
  end
end
