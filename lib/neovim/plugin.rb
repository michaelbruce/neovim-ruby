require "neovim/plugin/dsl"

module Neovim
  # @api private
  class Plugin
    attr_accessor :handlers
    attr_reader :source

    # Entrypoint to the +Neovim.plugin+ DSL.
    def self.from_config_block(source)
      new(source).tap do |instance|
        yield DSL.new(instance) if block_given?
      end
    end

    def initialize(source)
      @handlers = []
      @source = source
    end

    # Return specs used by +nvim+ to register plugins.
    def specs
      @handlers.inject([]) do |acc, handler|
        handler.qualified? ? acc + [handler.to_spec] : acc
      end
    end
  end
end
