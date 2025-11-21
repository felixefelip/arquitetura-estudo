# rbs_inline: enabled

module Academico
  class CursosController < ApplicationController
    #: -> void
    def index
      @cursos = ::Academico::Curso::Entity.all
      @usuario = session[:user_name]
    end

    #: -> void
    def update
      curso = ::Academico::Curso::Entity.find(params[:id])

      curso.update!(assistido: true)

      redirect_to academico_cursos_path, notice: "Curso marcado como assistido!"
    end
  end
end
