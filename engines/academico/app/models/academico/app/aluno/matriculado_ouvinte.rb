module Academico::App::Aluno
  class MatriculadoOuvinte
    def reage_ao(payload:)
      self.client_payload = payload.fetch(:client_payload)

      momento = payload.fetch(:momento)

      messagem = "Aluno com CPF #{client_payload.fetch(:document)}
                          foi matriculado na data #{momento}"

      Rails.logger.info messagem

      matricular_aluno
    end

    private

    attr_accessor :client_payload

    def matricular_aluno
      repo = Academico::Infra::Aluno::Repositories::ActiveRecord::Impl.new

      aluno_dto = Academico::App::Aluno::Matricular::Dto.new(
        cpf: client_payload.fetch(:document),
        nome: client_payload.fetch(:full_name),
        email: client_payload.fetch(:email),
      )

      Academico::App::Aluno::Matricular.new(
        aluno_repository: repo,
      ).call(aluno_dto:)
    end
  end
end
