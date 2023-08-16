module Academico
  module Domain
    module Aluno
      class CifradorDeSenha
        extend ActiveSupport::Concern

        included do
          def cifrar(senha:)
            raise NotImplementedError
          end

          def verificar(senha_em_texto:, senha_cifrada:)
            raise NotImplementedError
          end
        end
      end
    end
  end
end
