module Academico
  module Infra
    module Aluno
      module Repositories
        class Memoria
          def adicionar(aluno:)
            alunos << aluno
          end

          def buscar_por_cpf(cpf)
            aluno = alunos.detect { |a| a.cpf == cpf }

            raise StandardError if aluno.nil?

            aluno
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
