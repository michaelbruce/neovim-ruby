require "neovim/session/api/version"

module Neovim
  class Session
    # @api private
    class API
      attr_reader :channel_id

      # Represents an unknown API. Used as a stand-in when the API hasn't been
      # discovered yet via the +vim_get_api_info+ RPC call.
      def self.null
        new([nil, {"version" => {}, "functions" => [], "types" => []}])
      end

      def initialize(payload)
        @channel_id, api_info = payload
        @methods = {}
        @method_names = {}

        @versions = Version.compatible(
          api_info.fetch("version", {}),
          api_info.fetch("types"),
          api_info.fetch("functions")
        )
      end

      def each_ext_type(&block)
        @versions.first.each_ext_type(&block)
      end

      def methods(target)
        @methods.fetch(target.class) do |klass|
          @methods[klass] = @versions.inject([]) do |acc, vers|
            acc | vers.methods(target)
          end
        end
      end

      def method_names(target)
        @method_names.fetch(target.class) do |klass|
          @method_names[klass] = @versions.inject([]) do |acc, vers|
            acc | vers.method_names(target)
          end
        end
      end

      def method(target, name)
        @versions.each do |vers|
          _method = vers.method(target, name)
          return(_method) if _method
        end

        nil
      end

      # Truncate the output of inspect so console sessions are more pleasant.
      def inspect
        "#<#{self.class}:0x%x @types={...} @functions={...}>" % (object_id << 1)
      end
    end
  end
end
