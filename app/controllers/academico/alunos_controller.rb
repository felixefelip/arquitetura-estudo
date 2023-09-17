module Academico
  class AlunosController < ApplicationController
    def index
      repo = Academico::Infra::Aluno::Repositories::ActiveRecord::Impl.new

      alunos = repo.buscar_todos

      render json: alunos
    end

    def create
      repo = Academico::Infra::Aluno::Repositories::ActiveRecord::Impl.new
      $publicador = Shared::Domain::Evento::Publicador.new
      aluno_dto = Academico::App::Aluno::Matricular::Dto.new(
        cpf: "123456",
        nome: "Felipe",
        email: "felipe@email.com",
      )

      Academico::App::Aluno::Matricular::Create.new(
        aluno_repository: repo,
        publicador_de_evento: $publicador,
      ).call(aluno_dto:)
    end
  end
end
