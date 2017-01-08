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
        @types, @functions = api_info.values_at("types", "functions")
        @method_names = {}
        @methods = {}

        @version = Version.new(api_info.fetch("version", {}))
      end

      def each_ext_type
        @types.each do |name, info|
          klass = Neovim.const_get(name)
          id = info.fetch("id")

          yield(klass, id) if block_given?
        end
      end

      def methods(target)
        @methods.fetch(target.class) do |klass|
          @methods[klass] = @functions.inject({}) do |acc, func_def|
            if level = @version.applicable_to(target, func_def, @types)
              method_name, function = level.build_function
              acc.merge(method_name => function)
            else
              acc
            end
          end
        end
      end

      def method_names(target)
        @method_names.fetch(target.class) do |klass|
          @method_names[klass] = methods(target).keys
        end
      end

      def method(target, name)
        methods(target).fetch(name, nil)
      end

      # Truncate the output of inspect so console sessions are more pleasant.
      def inspect
        "#<#{self.class}:0x%x @types={...} @functions={...}>" % (object_id << 1)
      end
    end
  end
end
