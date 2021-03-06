require "pact/message/consumer/rspec"
require "fileutils"

RSpec.describe "creating a message pact" do

  ZOO_PACT_FILE_PATH = "spec/pacts/zoo_consumer-zoo_provider.json"

  before(:all) do
    Pact.message_consumer "Zoo Consumer" do
      has_pact_with "Zoo Provider" do
        builder :alice_producer do
          pact_specification_version '2'
        end
      end
    end

    FileUtils.rm_rf ZOO_PACT_FILE_PATH
  end

  class MessageHandler

    attr_reader :output_stream

    def initialize
      @output_stream = StringIO.new
    end

    def call(content_string)
      message = OpenStruct.new(JSON.parse(content_string))
      output_stream.print "Hello #{message.name}"
    end
  end

  let(:message_handler) { MessageHandler.new }

  it "allows a consumer to test that it can handle a message example correctly", pact: :message do
    alice_producer
      .given("there is an alligator named Mary")
      .is_expected_to_send("an alligator message")
      .with_metadata(type: 'animal')
      .with_content(name: "Mary")

    alice_producer.send_message do | content_string |
      message_handler.call(content_string)
    end

    expect(message_handler.output_stream.string).to eq ("Hello Mary")
  end

  it "allows a consumer to test that it can handle a second message example correctly", pact: :message do
    alice_producer
      .given("there is an alligator named John")
      .is_expected_to_send("an alligator message")
      .with_content(name: "John")

    alice_producer.send_message do | content_string |
      message_handler.call(content_string)
    end

    expect(message_handler.output_stream.string).to eq ("Hello John")
  end

  it "merges the message into the pact file" do
    pact_hash = JSON.parse(File.read(ZOO_PACT_FILE_PATH), symbolize_names: true)
    expect(pact_hash[:consumer][:name]).to eq "Zoo Consumer"
    expect(pact_hash[:provider][:name]).to eq "Zoo Provider"
    expect(pact_hash[:messages].size).to eq 2
  end
end
