module Academico
  module Aluno
    module TelefoneRepositories
      module ActiveRecord
        class Record < ApplicationRecord
          self.table_name = "telefones"

          belongs_to :aluno,
                      inverse_of: :telefones,
                      class_name: "Academico::Aluno::Repositories::ActiveRecord::Record"

          validates :ddd, presence: true
        end

        private_constant :Record
      end
    end
  end
end
