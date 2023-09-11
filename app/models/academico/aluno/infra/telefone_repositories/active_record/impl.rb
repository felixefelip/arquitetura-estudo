module Academico
  module Aluno
    module Infra
      module TelefoneRepositories
        module ActiveRecord
          class Impl
            # include ::Academico::Aluno::Domain::Repository

            def buscar_todos
              Record.all
            end
          end
        end
      end
    end
  end
end
