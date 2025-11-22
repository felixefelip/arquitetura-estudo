# rbs_inline: enabled

module Marketing::Leads
  class FormComponent < ViewComponent::Base
    #: (lead: Marketing::Lead::Entity, plano: Hash[Symbol, untyped]) -> void
    def initialize(lead:, plano:)
      super()
      self.lead = lead
      self.plano = plano
    end

    # @rbs!
    #   include ActionView::Helpers::FormHelper[:full_name | :email]

    private

    attr_accessor :lead #: Marketing::Lead::Entity
    attr_accessor :plano #: Hash[Symbol, untyped]
  end
end
