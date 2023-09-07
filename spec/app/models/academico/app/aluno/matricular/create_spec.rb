require "rails_helper"

RSpec.describe Academico::App::Aluno::Matricular::Create do
  describe "#call" do
    it "cria um aluno", :aggregate_failures do
      repo = Academico::Infra::Aluno::Repositories::ActiveRecord::Impl.new
      publicador = Shared::Domain::Evento::Publicador.new
      aluno_dto = Academico::App::Aluno::Matricular::Dto.new(
        cpf: "123456",
        nome: "Felipe",
        email: "felipe@email.com",
      )

      described_class.new(
        aluno_repository: repo,
        publicador_de_evento: publicador,
      ).call(aluno_dto:)

      aluno_busca = repo.buscar_por_cpf(aluno_dto.cpf)
      expect(aluno_busca).to be_present
      expect(aluno_busca).to be_a(Academico::Domain::Aluno::Entity)
    end
  end
end
