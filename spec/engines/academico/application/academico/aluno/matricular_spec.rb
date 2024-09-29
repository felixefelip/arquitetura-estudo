require "rails_helper"

RSpec.describe Academico::Aluno::Matricular do
  describe "#call" do
    it "cria um aluno", :aggregate_failures do
      repo = Academico::Aluno::ActiveRecord::Impl.new
      publicador = Shared::Domain::Evento::Publicador.new

      ouvinte_log_matriculado = Academico::Aluno::LogMatriculado.new
      publicador.adicionar_ouvinte(ouvinte: ouvinte_log_matriculado)

      aluno_dto = Academico::Aluno::Matricular::Dto.new(
        cpf: "123456",
        nome: "Felipe",
        email: "felipe@email.com",
      )

      expect(ouvinte_log_matriculado).to receive(:reage_ao).once

      described_class.new(
        aluno_repository: repo,
        publicador_de_evento: publicador,
      ).call(aluno_dto:)

      aluno_busca = repo.buscar_por_cpf(Shared::Domain::Cpf.new(numero: aluno_dto.cpf))
      expect(aluno_busca).to be_present
      expect(aluno_busca).to be_a(Academico::Aluno::Entity)
    end

    context "quando com repo de memoria" do
      it "cria um aluno", :aggregate_failures do
        repo = Academico::Aluno::Memoria.new
        publicador = Shared::Domain::Evento::Publicador.new

        ouvinte_log_matriculado = Academico::Aluno::LogMatriculado.new
        publicador.adicionar_ouvinte(ouvinte: ouvinte_log_matriculado)

        aluno_dto = Academico::Aluno::Matricular::Dto.new(
          cpf: "123456",
          nome: "Felipe",
          email: "felipe@email.com",
        )

        expect(ouvinte_log_matriculado).to receive(:reage_ao).once

        described_class.new(
          aluno_repository: repo,
          publicador_de_evento: publicador,
        ).call(aluno_dto:)

        aluno_busca = repo.buscar_por_cpf(Shared::Domain::Cpf.new(numero: aluno_dto.cpf))
        expect(aluno_busca).to be_present
        expect(aluno_busca).to be_a(Academico::Aluno::Entity)
      end
    end
  end
end
