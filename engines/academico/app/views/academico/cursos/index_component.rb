# rbs_inline: enabled

module Academico::Cursos
  class IndexComponent < ViewComponent::Base
    #: (cursos: Academico::Curso::Entity::ActiveRecord_Relation, usuario: String?) -> void
    def initialize(cursos:, usuario:)
      super()
      self.cursos = cursos
      self.usuario = usuario
    end

    private

    attr_accessor :cursos #: Academico::Curso::Entity::ActiveRecord_Relation
    attr_accessor :usuario #: String?
  end
end
