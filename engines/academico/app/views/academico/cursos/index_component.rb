# rbs_inline: enabled

module Academico::Cursos
  class IndexComponent < ViewComponent::Base
    # @rbs @cursos: Academico::Curso::Entity::ActiveRecord_Relation
    # @rbs @usuario: String?

    #: (cursos: Academico::Curso::Entity::ActiveRecord_Relation, usuario: String?) -> void
    def initialize(cursos:, usuario:)
      super()
      @cursos = cursos
      @usuario = usuario
    end
  end
end
