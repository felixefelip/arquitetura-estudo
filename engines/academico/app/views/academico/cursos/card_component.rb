# rbs_inline: enabled

module Academico::Cursos
  class CardComponent < ViewComponent::Base
    # @rbs @curso: Academico::Curso::Entity

    #: (curso: Academico::Curso::Entity) -> void
    def initialize(curso:)
      super
      @curso = curso
    end

    #: -> bool
    def disabled?
      @curso.icone.present?
    end

    #: -> String
    def button_text
      disabled? ? "Assistido" : "Marcar como assistido"
    end
  end
end
