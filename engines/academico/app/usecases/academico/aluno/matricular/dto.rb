module Academico
  module Aluno
    class Matricular
      class Dto
        include ActiveModel::Validations

        attr_reader :cpf, :email, :nome, :senha

        validates :cpf, presence: true
        validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
        validates :nome, presence: true

        def initialize(cpf:, nome:, email:)
          self.cpf = cpf
          self.nome = nome
          self.email = email
        end

        def cpf!
          cpf || raise
        end

        def email!
          email || raise
        end

        def nome!
          nome || raise
        end

        private

        attr_writer :cpf, :email, :nome
      end
    end
  end
end
