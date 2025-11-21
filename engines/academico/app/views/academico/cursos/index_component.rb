# frozen_string_literal: true

class Academico::Cursos::IndexComponent < ViewComponent::Base
  def initialize(cursos:, usuario:)
    @cursos = cursos
    @usuario = usuario
  end
end
