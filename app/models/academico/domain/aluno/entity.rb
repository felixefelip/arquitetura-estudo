module Academico
  module Domain
    module Aluno
      class Entity
        attr_reader :cpf, :email, :nome, :telefones, :senha

        def initialize(cpf:, nome:, email:)
          self.cpf = Cpf.new(numero: cpf)
          self.nome = nome
          self.email = email
        end

        def adicionar_telefone(ddd:, numero:)
          raise StandardError if telefones.count == 2

          telefones << Telefone.new(ddd:, numero:)
        end

        private

        attr_writer :cpf, :email, :nome, :telefones, :senha
      end
    end
  end
end
