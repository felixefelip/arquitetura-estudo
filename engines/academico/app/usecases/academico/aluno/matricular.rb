# rbs_inline: enabled

module Academico
  module Aluno
    class Matricular
      attr_accessor :errors #: ActiveModel::Errors

      # @rbs (aluno_dto: Dto, ?aluno_repository: Academico::Aluno::_Repository) -> void
      def initialize(aluno_dto:, aluno_repository: Academico::Aluno::Repositories::ActiveRecord::Impl.new)
        self.aluno_repository = aluno_repository
        self.aluno_dto = aluno_dto
        self.errors = aluno_dto.errors
      end

      # @rbs -> bool
      def call
        aluno_dto.validate!

        aluno = ::Academico::Aluno::Entity.new(
          cpf: aluno_dto.cpf!, nome: aluno_dto.nome!, email: aluno_dto.email!, senha: aluno_dto.senha,
        )

        aluno_repository.adicionar(aluno:)

        publicar_evento(aluno:)

        SuccessMailer.send_mail(aluno).deliver

        true
      end

      private

      attr_accessor :aluno_repository #: Academico::Aluno::_Repository
      attr_accessor :aluno_dto #: Dto

      # @rbs (aluno: Academico::Aluno::Entity) -> void
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
end
