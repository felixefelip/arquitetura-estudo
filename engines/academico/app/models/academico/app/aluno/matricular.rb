module Academico::App::Aluno
  class Matricular
    def initialize(aluno_repository:)
      self.aluno_repository = aluno_repository
    end

    def call(aluno_dto:)
      aluno = ::Academico::Domain::Aluno::Entity.new(
        cpf: aluno_dto.cpf, nome: aluno_dto.nome, email: aluno_dto.email, senha: "123456",
      )

      aluno_repository.adicionar(aluno:)

      publicar_evento(aluno:)

      SuccessMailer.send_mail(aluno).deliver
    end

    private

    attr_accessor :aluno_repository

    def publicar_evento(aluno:)
      payload = {
        cpf_aluno: aluno.cpf,
        momento: DateTime.current,
        name: "aluno_matriculado",
      }

      ActiveSupport::Notifications.instrument("aluno_matriculado", payload) do
        Rails.logger.info "Evento aluno_matriculado publicado para o aluno #{aluno.nome}"
      end
    end
  end
end
