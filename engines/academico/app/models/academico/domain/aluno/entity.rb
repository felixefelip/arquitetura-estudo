# rbs_inline: enabled

module Academico::Domain::Aluno
  class Entity
    attr_reader :cpf #: ::Shared::Domain::Cpf
    attr_reader :email #: Email
    attr_reader :nome #: String
    attr_reader :telefones #: Array[Telefone]
    attr_reader :senha #: String?

    # @rbs (cpf: ::String, nome: ::String, email: ::String, ?senha: ::String?) -> void
    def initialize(nome:, email:, cpf:, senha: nil)
      self.nome = nome
      self.email = Email.new(endereco: email)
      self.cpf = ::Shared::Domain::Cpf.new(numero: cpf)
      self.senha = senha
    end

    # @rbs (ddd: ::String, numero: ::String) -> void
    def adicionar_telefone(ddd:, numero:)
      raise StandardError if telefones.count == 2

      telefones << Telefone.new(ddd:, numero:)
    end

    private

    attr_writer :cpf #: ::Shared::Domain::Cpf
    attr_writer :email #: Email
    attr_writer :nome #: String
    attr_writer :telefones #: Array[Telefone]
    attr_writer :senha #: String?
  end
end
