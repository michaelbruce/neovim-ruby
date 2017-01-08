require "helper"

module Neovim
  class Session
    class API
      RSpec.describe Version do
        let(:session) { double(:discover_api => nil, :api => nil) }

        shared_context "applicability" do
          describe "#applicable?" do
            it "returns true" do
              applicable_funcs.each do |func|
                expect(version.applicable?(target, func, types)).to be(true),
                  "Expected #{func.inspect} to be applicable but wasn't"
              end
            end

            it "returns false" do
              inapplicable_funcs.each do |func|
                expect(version.applicable?(target, func, types)).to be(false),
                  "Expected #{func.inspect} not to be applicable but was"
              end
            end
          end
        end

        describe "latest version" do
          let(:version) do
            Version.new("api_level" => 1, "api_compatible" => 0)
          end

          context "client methods" do
            include_context "applicability" do
              let(:applicable_funcs) do
                [
                  {"name" => "nvim_func", "method" => false, "since" => 1},
                  {"name" => "vim_func", "method" => false, "since" => 0}
                ]
              end

              let(:inapplicable_funcs) do
                [
                  {"name" => "nvim_buf_func", "method" => true, "since" => 1},
                  {"name" => "buffer_func", "method" => true, "since" => 0},
                ]
              end

              let(:types) { {} }
              let(:target) { Neovim::Client.new(session) }
            end
          end

          context "remote object methods" do
            include_context "applicability" do
              let(:applicable_funcs) do
                [
                  {"name" => "nvim_buf_func", "method" => true, "since" => 1},
                  {"name" => "buffer_func", "method" => false, "since" => 0}
                ]
              end

              let(:inapplicable_funcs) do
                [
                  {"name" => "vim_func", "method" => false, "since" => 0},
                  {"name" => "window_func", "method" => true, "since" => 0},
                  {"name" => "nvim_func", "method" => false, "since" => 1},
                  {"name" => "nvim_win_func", "method" => true, "since" => 1}
                ]
              end

              let(:types) { {"Buffer" => {"prefix" => "nvim_buf_"}} }
              let(:target) { Neovim::Buffer.new(0, session) }
            end
          end
        end

        describe "legacy versions" do
          let(:version) do
            Version.new({})
          end

          context "client methods" do
            include_context "applicability" do
              let(:applicable_funcs) { [{"name" => "vim_func"}] }
              let(:inapplicable_funcs) { [{"name" => "buffer_func"}] }
              let(:types) { {} }
              let(:target) { Neovim::Client.new(session) }
            end
          end

          context "remote object methods" do
            include_context "applicability" do
              let(:applicable_funcs) { [{"name" => "buffer_func"}] }
              let(:inapplicable_funcs) { [{"name" => "vim_func"}] }
              let(:types) { {} }
              let(:target) { Neovim::Buffer.new(0, session) }
            end
          end
        end
      end
    end
  end
end
