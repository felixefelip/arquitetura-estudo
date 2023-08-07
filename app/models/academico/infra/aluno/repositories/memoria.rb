module Academico
  module Infra
    module Aluno
      module Repositories
        class Memoria
          include ::Academico::Domain::Aluno::Repository

          def adicionar(aluno)
            alunos << aluno
          end

          def buscar_por_cpf(cpf)
            alunos.detect { |aluno| aluno.cpf == cpf }
          end

          def buscar_todos
            alunos
          end

          private

          def alunos
            @alunos ||= []
          end
        end
      end
    end
  end
end
