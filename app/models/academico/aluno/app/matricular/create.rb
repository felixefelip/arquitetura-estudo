module Academico
  module Aluno
    module App
      module Matricular
        class Create
          def initialize(aluno_repository:, publicador_de_evento:)
            self.aluno_repository = aluno_repository
            self.publicador_de_evento = publicador_de_evento
          end

          def call(aluno_dto:)
            aluno = ::Academico::Aluno::Domain::Entity.new(
              cpf: aluno_dto.cpf, nome: aluno_dto.nome, email: aluno_dto.email,
            )

            aluno_repository.adicionar(aluno:)

            evento = ::Academico::Aluno::Domain::Matriculado.new(cpf_aluno: aluno.cpf)
            publicador_de_evento.publicar(evento:)
          end

          private

          attr_accessor :aluno_repository, :publicador_de_evento
        end
      end
    end
  end
end
