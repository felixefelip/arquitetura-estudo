module Shared
  module Evento
    class Publicador
      def adicionar_ouvinte(ouvinte:)
        ouvintes << ouvinte
      end

      def publicar(evento:)
        ouvintes.each { |ouvinte| ouvinte.processa(evento:) }
      end

      private

      def ouvintes
        @ouvintes ||= []
      end
    end
  end
end
