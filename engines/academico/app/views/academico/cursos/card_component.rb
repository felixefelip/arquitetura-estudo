# rbs_inline: enabled

module Academico::Cursos
  class CardComponent < ViewComponent::Base
    #: (curso: Academico::Curso::Entity) -> void
    def initialize(curso:)
      super()
      self.curso = curso
    end

    #: -> bool
    def disabled?
      # @curso.icone.present?
      false
    end

    #: -> String
    def button_text
      disabled? ? "Assistido" : "Marcar como assistido"
    end

    private

    attr_accessor :curso #: Academico::Curso::Entity
  end
end
