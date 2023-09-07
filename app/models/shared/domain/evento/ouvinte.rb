module Shared::Domain
  module Evento
    class Ouvinte
      def processa(evento:)
        reage_ao?(evento:) if sabe_processar?(evento:)
      end

      def sabe_processar?(evento:)
        raise NotImplementedError
      end

      def reage_ao?(evento:)
        raise NotImplementedError
      end
    end
  end
end
