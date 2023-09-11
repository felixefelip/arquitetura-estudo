module Academico
  module Aluno
    module Infra
      module TelefoneRepositories
        module ActiveRecord
          class Record < ApplicationRecord
            self.table_name = "telefones"

            belongs_to :aluno,
                       inverse_of: :telefones,
                       class_name: "Academico::Aluno::Infra::Repositories::ActiveRecord::Record"

            validates :ddd, presence: true

            def teste
              self.ddd = "1"

              ddd&.capitalize

              aluno&.telefones&.first!&.numero = "1"

              aluno.nome

              # aluno.nome = 1
            end
          end

          private_constant :Record
        end
      end
    end
  end
end
