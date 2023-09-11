module Academico
  module Aluno
    module Domain
      class Telefone
        attr_reader :ddd, :numero

        def initialize(ddd:, numero:)
          self.ddd = ddd
          self.numero = numero
        end

        def to_s
          "(#{ddd}) #{numero}"
        end

        private

        attr_writer :ddd, :numero
      end
    end
  end
end
