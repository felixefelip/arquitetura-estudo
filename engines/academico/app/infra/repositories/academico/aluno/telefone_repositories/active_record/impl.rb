module Academico
  module Infra
    module Aluno
      module TelefoneRepositories
        module ActiveRecord
          class Impl
            # include ::Academico::Domain::Aluno::Repository

            def buscar_todos
              Record.all
            end
          end
        end
      end
    end
  end
end
