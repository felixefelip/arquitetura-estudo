module Academico
  class AlunosController < ApplicationController
    def index
      repo = Academico::Aluno::ActiveRecord::Impl.new

      alunos = repo.buscar_todos

      render json: alunos
    end

    def create
      repo = Academico::Aluno::ActiveRecord::Impl.new

      aluno_dto = Academico::Aluno::Matricular::Dto.new(
        cpf: "123456",
        nome: "Felipe",
        email: "felipe@email.com",
      )

      Academico::Aluno::Matricular.new(
        aluno_repository: repo,
        publicador_de_evento: $publicador,
      ).call(aluno_dto:)
    end
  end
end
