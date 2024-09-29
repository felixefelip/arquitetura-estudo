module Academico
  module Aluno
    class Entity
      attr_reader :cpf, :email, :nome, :telefones, :senha

      def initialize(nome:, email:, cpf:, senha: nil)
        self.nome = nome
        self.email = Email.new(endereco: email)
        self.cpf = ::Shared::Domain::Cpf.new(numero: cpf)
        self.senha = senha
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
