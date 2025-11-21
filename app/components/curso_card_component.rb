# frozen_string_literal: true

class CursoCardComponent < ViewComponent::Base
  def initialize(curso:)
    @curso = curso
  end

  def disabled?
    @curso.assistido
  end

  def button_text
    disabled? ? "Assistido" : "Marcar como assistido"
  end
end
