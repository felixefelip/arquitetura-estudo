module Academico
  module Aluno
    class Matricular
      class Dto
        include ActiveModel::Validations

        attr_reader :cpf, :email, :nome, :senha

        validates :cpf, presence: true
        validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
        validates :nome, presence: true
        validates :senha, presence: true, length: { minimum: 6 }

        def initialize(cpf:, nome:, email:)
          self.cpf = cpf
          self.nome = nome
          self.email = email
        end

        private

        attr_writer :cpf, :email, :nome, :senha
      end
    end
  end
end
