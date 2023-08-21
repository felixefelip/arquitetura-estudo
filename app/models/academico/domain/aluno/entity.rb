module Academico
  module Domain
    module Aluno
      class Entity
        attr_reader :cpf, :email, :nome, :telefones, :senha

        def initialize(nome:, email:, cpf:)
          self.cpf = ::Shared::Domain::Cpf.new(numero: cpf)
          self.nome = nome
          self.email = email

          telefones.first.ddd = "1"
        end

        def adicionar_telefone(ddd:, numero:)
          raise StandardError if telefones.count == 2

          telefones << Telefone.new(ddd:, numero:)
        end

        def one
          1
        end

        private

        attr_writer :cpf, :email, :nome, :telefones, :senha
      end
    end
  end
end
