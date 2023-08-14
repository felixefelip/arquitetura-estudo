module Academico
  module Infra
    module Aluno
      module Repositories
        module ActiveRecord
          class Record < ApplicationRecord
            self.table_name = "academico_alunos"
          end

          private_constant :Record
        end
      end
    end
  end
end
