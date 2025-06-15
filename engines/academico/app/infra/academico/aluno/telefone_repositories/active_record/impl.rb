module Academico
  module Aluno
    module TelefoneRepositories
      module ActiveRecord
        class Impl
          def buscar_todos
            Record.all
          end
        end
      end
    end
  end
end
