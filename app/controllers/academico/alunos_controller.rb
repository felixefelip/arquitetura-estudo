module Academico
  class AlunosController < ApplicationController
    def index
      repo = Academico::Infra::Aluno::Repositories::ActiveRecord::Impl.new

      @alunos = repo.buscar_todos

      render json: @alunos
    end
  end
end
