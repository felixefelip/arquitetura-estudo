module Academico
  module App
    module Aluno
      module Matricular
        class Create
          def initialize(aluno_repository:, publicador_de_evento:)
            self.aluno_repository = aluno_repository
            self.publicador_de_evento = publicador_de_evento
          end

          def call(aluno_dto:)
            # raise StandardError unless aluno_dto.is_a?(::Academico::App::Aluno::Matricular::Dto)

            aluno = ::Academico::Domain::Aluno::Record.new(
              cpf: aluno_dto.cpf, nome: aluno_dto.nome, email: aluno_dto.email,
            )

            aluno_repository.adicionar(aluno)
          end

          private

          attr_accessor :aluno_repository, :publicador_de_evento
        end
      end
    end
  end
end
