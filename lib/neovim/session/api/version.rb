require "neovim/session/api/function"

module Neovim
  class Session
    class API
      class Version
        def initialize(version_hash)
          lev_beg, lev_end = version_hash.values_at(
            "api_compatible", "api_level"
          ).map(&:to_i)

          @levels = (lev_beg..lev_end).map { |int| Level.from(int) }
        end

        def applicable_to(target, func_def, types)
          @levels.each do |level|
            level.applicable?(target, func_def, types)
          end
        end

        def build_function(func_def, types)
          name, async, dep, method = func_def.values_at(
            "name", "async", "deprecated_since", "method"
          )

          [method_name, function]
        end

        module Level
          def self.from(int)
            int == 0 ? Legacy.new : Latest.new
          end

          class Legacy
            def applicable?(target, func_def, types)
              return false if func_def["since"].to_i > 0

              case target
              when ::Neovim::Client
                prefix = "vim_"
              when ::Neovim::RemoteObject
                name = target.class.to_s.split("::").last
                prefix = "#{name.downcase}_"
              else
                return false
              end

              func_def["name"].start_with?(prefix)
            end
          end

          class Latest
            def applicable?(target, func_def, types)
              return false if func_def["since"].to_i < 1

              case target
              when ::Neovim::Client
                return false if func_def["method"] == true
                prefix = "nvim_"
              when ::Neovim::RemoteObject
                return false if func_def["method"] == false
                name = target.class.to_s.split("::").last
                prefix = types.fetch(name).fetch("prefix")
              else
                return false
              end

              func_def["name"].start_with?(prefix)
            end
          end
        end
      end
    end
  end
end
