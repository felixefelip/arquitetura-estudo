module Shared
  class Cpf
    def initialize(numero:)
      self.numero = numero
    end

    def to_s
    end

    private

    attr_accessor :numero
  end
end
