require "fluent/output"

class Fluent::TwitterOutput < Fluent::Output
  Fluent::Plugin.register_output('twitter', self)

  config_param :consumer_key, :string, :secret => true
  config_param :consumer_secret, :string, :secret => true
  config_param :oauth_token, :string, :default => nil, :secret => true
  config_param :oauth_token_secret, :string, :default => nil, :secret => true
  config_param :access_token, :string, :default => nil, :secret => true
  config_param :access_token_secret, :string, :default => nil, :secret => true

  def initialize
    super
    require 'twitter'
  end

  def configure(conf)
    super

    @access_token = @access_token || @oauth_token
    @access_token_secret = @access_token_secret || @oauth_token_secret
    if !@consumer_key or !@consumer_secret or !@access_token or !@access_token_secret
      raise Fluent::ConfigError, "missing values in consumer_key or consumer_secret or oauth_token or oauth_token_secret"
    end

    @twitter = Twitter::REST::Client.new(
      :consumer_key => @consumer_key,
      :consumer_secret => @consumer_secret,
      :access_token => @access_token,
      :access_token_secret => @access_token_secret
    )
  end

  def emit(tag, es, chain)
    es.each do |time,record|
      tweet(record['user'], record['message'])
    end

    chain.next
  end

  def tweet(user, message)
    begin
      if user.nil?
        @twitter.update(message)
      else
        @twitter.create_direct_message(user, message)
      end
    rescue Twitter::Error => e
      $log.error("Twitter Error: #{e.message}")
    end
  end
end

