# rbs_inline: enabled

module Academico
  module Aluno
    class Matricular
      class Dto
        include ActiveModel::Validations

        # @rbs!
        #   extend ActiveModel::Validations::ClassMethods

        attr_reader :cpf, :email, :nome, :senha #: String?

        validates :cpf, presence: true
        validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
        validates :nome, presence: true

        #: (cpf: String?, nome: String?, email: String?) -> void
        def initialize(cpf:, nome:, email:)
          self.cpf = cpf
          self.nome = nome
          self.email = email
        end

        #: -> String
        def cpf!
          cpf || raise
        end

        #: -> String
        def email!
          email || raise
        end

        #: -> String
        def nome!
          nome || raise
        end

        private

        attr_writer :cpf, :email, :nome #: String?
      end
    end
  end
end
