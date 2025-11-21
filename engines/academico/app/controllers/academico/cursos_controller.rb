# rbs_inline: enabled

module Academico
  class CursosController < ApplicationController
    #: -> void
    def index
      cursos = ::Academico::Curso::Entity.all

      render json: cursos
    end

    #: -> void
    def update
      curso = ::Academico::Curso::Entity.find(params[:id])

      curso.update!(assistido: true)

      render :json, status: :no_content
    end
  end
end
