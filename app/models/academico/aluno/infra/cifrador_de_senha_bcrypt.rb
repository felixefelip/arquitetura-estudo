module Academico
  module Aluno
    module Infra
      class CifradorDeSenhaBcrypt < ::Academico::Aluno::Domain::CifradorDeSenha
        def cifrar(senha:)
          BCrypt::Password.create(senha, {})
        end

        def verificar(senha_em_texto:, senha_cifrada:)
          raise TypeError unless senha_cifrada.is_a?(BCrypt::Password)

          senha_em_texto == senha_cifrada
        end
      end
    end
  end
end
