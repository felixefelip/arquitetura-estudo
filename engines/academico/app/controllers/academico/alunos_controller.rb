# rbs_inline: enabled

module Academico
  class AlunosController < ApplicationController
    def index
      repo = Academico::Aluno::Repositories::ActiveRecord::Impl.new

      alunos = repo.buscar_todos

      render json: alunos
    end

    def create
      aluno_dto = Academico::Aluno::Matricular::Dto.new(
        cpf: "123456",
        nome: "Felipe",
        email: "felipe@email.com",
      )

      Academico::Aluno::Matricular.new(
        aluno_dto: aluno_dto,
      ).call

      render json: { message: "Aluno matriculado com sucesso!" }, status: :created
    end
  end
end
