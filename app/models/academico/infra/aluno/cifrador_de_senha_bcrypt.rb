module Academico
  module Infra
    module Aluno
      class CifradorDeSenhaBcrypt < ::Academico::Domain::Aluno::CifradorDeSenha
        def cifrar(senha:)
          BCrypt::Password.create(senha)
        end

        def verificar(senha_em_texto:, senha_cifrada:)
          raise TypeError unless senha_cifrada.is_a?(BCrypt::Password)

          senha_em_texto == senha_cifrada
        end
      end
    end
  end
end
