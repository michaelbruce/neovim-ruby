require "socket"
require "helper"

module Neovim
  RSpec.describe MsgpackStream do
    shared_context "msgpack stream behavior" do
      it "sends and receives data" do
        stream = MsgpackStream.new(event_loop)
        client_messages = []

        server_thread = Thread.new do
          client = server.accept
          client_messages << client.readpartial(1024)

          client.write(MessagePack.pack([2]))
          client.close
          server.close
        end

        fiber = Fiber.new do
          msg_cb = Proc.new { |msg| Fiber.yield(msg) }
          stream.send([1]).run(msg_cb)
        end

        server_message = fiber.resume
        server_thread.join

        expect(server_message).to eq([2])
        expect(client_messages).to eq([MessagePack.pack([1])])
      end
    end

    context "tcp" do
      let!(:server) { TCPServer.new("0.0.0.0", 0) }
      let!(:event_loop) { EventLoop.tcp("0.0.0.0", server.addr[1]) }

      include_context "msgpack stream behavior"
    end

    context "unix" do
      let!(:server) { UNIXServer.new(Support.socket_path) }
      let!(:event_loop) { EventLoop.unix(Support.socket_path) }

      include_context "msgpack stream behavior"
    end
  end
end
