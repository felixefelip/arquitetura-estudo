module Shared
  module Domain
    module Evento
      class Ouvinte
        def processa(evento:)
          reage_ao(evento:) if sabe_processar?(evento:)
        end
      end
    end
  end
end
