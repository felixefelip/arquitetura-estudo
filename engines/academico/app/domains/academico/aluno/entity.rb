# rbs_inline: enabled

module Academico::Aluno
  class Entity
    attr_reader :cpf
    attr_reader :email
    attr_reader :nome
    attr_reader :telefones
    attr_reader :senha

    def initialize(nome:, email:, cpf:, senha: nil)
      self.nome = nome
      self.email = Email.new(endereco: email)
      self.cpf = ::Shared::Cpf.new(numero: cpf)
      self.senha = senha
    end

    def adicionar_telefone(ddd:, numero:)
      raise StandardError if telefones.count == 2

      telefones << Telefone.new(ddd:, numero:)
    end

    private

    attr_writer :cpf
    attr_writer :email
    attr_writer :nome
    attr_writer :telefones
    attr_writer :senha
  end
end
