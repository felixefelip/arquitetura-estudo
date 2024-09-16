module Academico
  module Infra
    module Aluno
      module Repositories
        module ActiveRecord
          class Record < ApplicationRecord
            self.table_name = "academico_alunos"

            has_many :telefones,
                     foreign_key: :academico_aluno_id,
                     inverse_of: :aluno,
                     dependent: :destroy,
                     class_name: "::Academico::Infra::Aluno::TelefoneRepositories::ActiveRecord::Record"

            def teste
              telefones.first!.numero
            end
          end

          private_constant :Record
        end
      end
    end
  end
end
