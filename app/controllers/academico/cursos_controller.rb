class Academico::CursosController < ApplicationController
  def index
    cursos = ::Academico::Domain::Curso::Entity.all

    render json: cursos
  end

  def update
    curso = ::Academico::Domain::Curso::Entity.find(params[:id])

    curso.update!(assitido: true)

    render :json, :no_content
  end
end
