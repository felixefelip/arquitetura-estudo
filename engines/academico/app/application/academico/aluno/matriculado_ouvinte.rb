module Academico
  module Aluno
    class MatriculadoOuvinte < ::Shared::Domain::Evento::Ouvinte
      def reage_ao(evento:)
        self.evento = evento

        evento.client_payload.deep_symbolize_keys!

        messagem = "Aluno com CPF #{evento.client_payload[:document]}
                            foi matriculado na data #{evento.momento}"

        Rails.logger.info messagem

        matricular_aluno
      end

      def sabe_processar?(evento:)
        evento.name == "finance_client_enrolled"
      end

      private

      attr_accessor :evento

      def matricular_aluno
        repo = Academico::Aluno::ActiveRecord::Impl.new

        aluno_dto = Academico::Aluno::Matricular::Dto.new(
          cpf: evento.client_payload[:document],
          nome: evento.client_payload[:full_name],
          email: evento.client_payload[:email],
        )

        Academico::Aluno::Matricular.new(
          aluno_repository: repo,
          publicador_de_evento: $publicador,
        ).call(aluno_dto:)
      end
    end
  end
end
