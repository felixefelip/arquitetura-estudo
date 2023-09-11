module Academico
  module Email
    module Domain
      class ValueObject
        def initialize(endereco:)
          raise ArgumentError unless endereco_valido?

          self.endereco = endereco
        end

        private

        attr_accessor :endereco

        def endereco_valido?
          true
        end
      end
    end
  end
end
