# frozen_string_literal: true

require "sinatra"
require "json"
require "slack_ruby_client"
require "securerandom"

if development? || test?
  require "dotenv"
  Dotenv.load
end

Slack.configure do |config|
  config.token = ENV.fetch("SLACK_TOKEN")
end
Slack::Events::Config.reset

class App < Sinatra::Application
  set :default_content_type, :json

  SLACK_CLIENT = Slack::Web::Client.new
  BOT_USER_ID = SLACK_CLIENT.auth_test.fetch("user_id")
  MESSAGES = [
    ":crustacean: :crustacean: :crustacean: [R] [U] [S] [T] [!] :crustacean: :crustacean: :crustacean:",
    "one day, we'll rewrite Rust in RUST.",
    "did someone say RUST? https://www.youtube.com/watch?v=QVw5mnRI8Zw",
    "Stainless steel? Needs more RUST.",
    "My favorite CoD level? RUST.",
    "My wife gave me a Ruby. I sold it for a jar of RUST.",
    "rUsT ʇsnɹ rUsT ʇsnɹ rUsT ʇsnɹ rUsT ʇsnɹ",
    "I add iron to my elixirs, so my insides can RUST.",
    "0 days since last mention of RUST.",
    ":crustacean: 🆁  :crustacean: 🆄  :crustacean: 🆂  :crustacean: 🆃  :crustacean:"
  ]

  before do
    halt 403 unless Slack::Events::Request.new(request).valid?
  end


  post "/" do
    json = JSON.parse(request.body.read)

    if json.key?("challenge")
      { challenge: json.fetch("challenge") }.to_json
    elsif json.key?("event")
      handle_event(json.fetch("event"))
      "{}"
    end
  end

  def handle_event(event)
    type = event.fetch("type")

    case type
    when "reaction_added"
      item = event.fetch("item")
      channel = item.fetch("channel")
      ts = item.fetch("ts")
      user = event.fetch("user")

      react_with_rust(channel, ts) if real_user?(user) && event.fetch("reaction") == "crustacean"
    when "message"
      maybe_reply(event)
    end
  end

  def react_with_rust(channel, ts)
    SLACK_CLIENT.reactions_add(channel: channel, timestamp: ts, name: "crustacean")
  rescue Slack::Web::Api::Errors::AlreadyReacted
    nil
  end

  def maybe_reply(event) # (with rust)
    # happens when things like video / image previews load. for our purposes this
    # amounts to a redundant message and we can safely ignore it.
    return if event["subtype"] == "message_changed"

    user = event.fetch("user")
    text = event.fetch("text")

    return unless real_user?(user) && rusty?(text)

    channel = event.fetch("channel")
    msg_ts = event.fetch("ts")
    thread_ts = event.fetch("thread_ts", msg_ts)

    react_with_rust(channel, msg_ts)

    reply = MESSAGES[SecureRandom.rand(MESSAGES.size)]
    chat_args = { text: reply, channel: channel, thread_ts: thread_ts }.compact

    SLACK_CLIENT.chat_postMessage(**chat_args)
  end

  def real_user?(user)
    user != BOT_USER_ID
  end

  def rusty?(text)
    text.downcase.match?(/rust/) || text == ":crustacean:"
  end

  run! if app_file == $0
end
