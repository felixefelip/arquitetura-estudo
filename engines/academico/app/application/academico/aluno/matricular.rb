module Academico
  module Aluno
    class Matricular
      def initialize(aluno_repository:, publicador_de_evento:)
        self.aluno_repository = aluno_repository
        self.publicador_de_evento = publicador_de_evento
      end

      def call(aluno_dto:)
        aluno = ::Academico::Aluno::Entity.new(
          cpf: aluno_dto.cpf, nome: aluno_dto.nome, email: aluno_dto.email, senha: "123456",
        )

        aluno_repository.adicionar(aluno:)

        evento = ::Academico::Aluno::Matriculado.new(cpf_aluno: aluno.cpf)
        publicador_de_evento.publicar(evento:)

        SuccessMailer.send_mail(aluno).deliver
      end

      private

      attr_accessor :aluno_repository, :publicador_de_evento
    end
  end
end
