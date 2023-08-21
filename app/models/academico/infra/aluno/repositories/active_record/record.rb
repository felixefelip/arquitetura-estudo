module Academico
  module Infra
    module Aluno
      module Repositories
        module ActiveRecord
          class Record < ApplicationRecord
            self.table_name = "academico_alunos"

            has_many :telefones,
                     dependent: :destroy,
                     class_name: "::Academico::Infra::Aluno::TelefoneRepositories::ActiveRecord::Record"

            def teste
              telefones.last!.numero
            end
          end

          private_constant :Record
        end
      end
    end
  end
end
