require "neovim/session/api/function"

module Neovim
  class Session
    class API
      module Version
        def self.compatible(version_hash, types, functions)
          api_level = version_hash.fetch("api_level", 0)
          api_compat = version_hash.fetch("api_compatible", 0)

          api_level.downto(api_compat).map do |level|
            const = "V#{level}"
            klass = const_defined?(const) ? const_get(const) : Future
            klass.new(types, functions, level)
          end
        end

        class Base
          def initialize(types, functions, api_level)
            @types, @functions = types, functions
            @level = api_level || 0
          end

          def each_ext_type
            @types.each do |name, info|
              klass = Neovim.const_get(name)
              id = info.fetch("id")

              yield(klass, id) if block_given?
            end
          end

          def methods(target)
            prefix = target_prefix(target)

            @functions.inject({}) do |acc, func_def|
              name, async, dep = extract_func_info(func_def)

              if name.start_with?(prefix)
                method_name = name.sub(/^#{prefix}/, "").to_sym
                acc.merge(method_name => Function.new(name, async, dep))
              else
                acc
              end
            end
          end

          def method_names(target)
            methods(target).keys
          end

          def method(target, name)
            methods(target).fetch(name.to_sym, nil)
          end
        end

        class V0 < Base
          private

          def extract_func_info(func_def)
            name, async = func_def.values_at("name", "async")
            [name, async, false]
          end

          def target_prefix(target)
            case target
            when ::Neovim::Client
              "vim_"
            else
              "#{target.class.to_s.split("::").last.downcase}_"
            end
          end
        end

        class V1 < Base
          private

          def extract_func_info(func_def)
            name, async = func_def.values_at("name", "async")
            dep_since = func_def["deprecated_since"]
            deprecated = dep_since && dep_since <= @level

            [name, async, deprecated]
          end

          def target_prefix(target)
            case target
            when ::Neovim::Client
              "nvim_"
            else
              name = target.class.to_s.split("::").last
              @types.fetch(name).fetch("prefix")
            end
          end
        end

        class Future < V1; end
      end
    end
  end
end
