module Academico
  class CursosController < ApplicationController
    def index
      cursos = ::Academico::Domain::Curso::Entity.all

      render json: cursos
    end

    def update
      curso = ::Academico::Domain::Curso::Entity.find(params[:id])

      curso.update!(assistido: true)

      render json: {}, status: :no_content
    end
  end
end
