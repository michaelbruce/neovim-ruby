module Neovim
  class Session
    class API
      # @api private
      class Function
        attr_reader :name, :async

        def initialize(name, async, deprecated)
          @name, @async, @deprecated = name, async, !!deprecated
        end

        def deprecated?
          @deprecated
        end

        # Apply this function to a running RPC session. Sends either a request if
        # +async+ is +false+ or a notification if +async+ is +true+.
        def call(session, *args)
          if deprecated?
            warn "WARNING: Use of deprecated API function #{name}"
          end

          if @async
            session.notify(@name, *args)
          else
            session.request(@name, *args)
          end
        end

        def ==(other)
          @name == other.name
        end
      end
    end
  end
end
