module Academico
  class AlunosController < ApplicationController
    def index
      repo = Academico::Aluno::Infra::Repositories::ActiveRecord::Impl.new

      alunos = repo.buscar_todos

      render json: alunos
    end

    def create
      repo = Academico::Aluno::Infra::Repositories::ActiveRecord::Impl.new
      publicador = Shared::Domain::Evento::Publicador.new
      aluno_dto = Academico::Aluno::App::Matricular::Dto.new(
        cpf: "123456",
        nome: "Felipe",
        email: "felipe@email.com",
      )

      Academico::Aluno::App::Matricular::Create.new(
        aluno_repository: repo,
        publicador_de_evento: publicador,
      ).call(aluno_dto:)
    end
  end
end
