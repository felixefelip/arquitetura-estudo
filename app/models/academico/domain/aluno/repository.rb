module Academico
  module Domain
    module Aluno
      class Repository
        def adicionar(aluno:)
          raise NotImplementedError
        end

        def buscar_por_cpf(cpf)
          raise NotImplementedError
        end

        def buscar_todos
          raise NotImplementedError
        end
      end
    end
  end
end
