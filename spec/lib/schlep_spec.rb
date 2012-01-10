require "spec_helper"

describe Schlep do
  before :each do
    Schlep.reset
  end

  after :each do
    %w[REDIS_URL REDISTOGO_URL].each do |e|
      ENV[e] = nil
    end
  end

  it "should be defined as a module" do
    Schlep.class.should be_a Module
  end

  context "#configure" do
    it "should be configurable with setters" do
      Schlep.app       = "test_app_1"
      Schlep.hostname  = "test_hostname_1"
      Schlep.redis_url = "redis://localhost:1234"

      Schlep.app.should == "test_app_1"
      Schlep.hostname.should == "test_hostname_1"
      Schlep.redis_url.should == "redis://localhost:1234"
    end

    it "should be configurable with a block" do
      Schlep.configure do |config|
        config.app       = "test_app_2"
        config.hostname  = "test_hostname_2"
        config.redis_url = "redis://localhost:4321"
      end

      Schlep.app.should == "test_app_2"
      Schlep.hostname.should == "test_hostname_2"
      Schlep.redis_url.should == "redis://localhost:4321"
    end
  end

  context "#envelope" do
    it "should return valid json" do
      lambda {
        JSON.parse(Schlep.envelope "test_type", { :one => { :two => 3 }})
      }.should_not raise_error(Exception)
    end
  end

  context "#hostname" do
    it "should be a string" do
      Schlep.hostname.should be_instance_of String
    end

    it "should not include a newline from the hostname command" do
      Schlep.hostname.should_not match /\s/
    end

    it "should not remove dashes, underscores, or periods" do
      Schlep.hostname = "this-is_a.hostname"

      Schlep.hostname.should == "this-is_a.hostname"
    end
  end

  context "#redis_url" do
    it "should connect locally by default" do
      Schlep.redis.client.host.should == "127.0.0.1"
      Schlep.redis.client.port.should == 6379
    end

    it "should connect to a basic url" do
      Schlep.redis_url = "redis://1.2.3.4:1234"

      Schlep.redis.client.host.should == "1.2.3.4"
      Schlep.redis.client.port.should == 1234
      Schlep.redis.client.password.should be_nil
    end

    it "should connect to a url with a username and password" do
      Schlep.redis_url = "redis://redis:password@1.2.3.4:1234"

      Schlep.redis.client.host.should == "1.2.3.4"
      Schlep.redis.client.port.should == 1234
      Schlep.redis.client.password.should == "password"
    end

    it "should detect the url from ENV[\"REDIS_URL\"]" do
      ENV["REDIS_URL"] = "redis://redis:secret@4.3.2.1:4321"

      Schlep.redis.client.host.should == "4.3.2.1"
      Schlep.redis.client.port.should == 4321
      Schlep.redis.client.password.should == "secret"
    end

    it "should detect the url from ENV[\"REDISTOGO_URL\"]" do
      ENV["REDISTOGO_URL"] = "redis://redis:secret@4.3.2.1:4321"

      Schlep.redis.client.host.should == "4.3.2.1"
      Schlep.redis.client.port.should == 4321
      Schlep.redis.client.password.should == "secret"
    end
  end

  context "#reset" do
    it "should reset instance variables to nil" do
      Schlep.configure do |config|
        config.app      = "test_app"
        config.hostname = "test_hostname"
      end

      Schlep.reset

      %w[app hostname redis].each do |ivar|
        Schlep.instance_variable_get("@#{ivar}").should be_nil
      end
    end
  end

  context "#serialize message" do
    it "should convert json to a hash" do
      Schlep.serialize_message("{\"one\":{\"two\":3}}").should == ({ "one" => { "two" => 3 }})
    end

    it "should leave strings alone" do
      Schlep.serialize_message("test string").should == "test string"
    end

    it "should leave arrays alone" do
      Schlep.serialize_message([1,2,[3,4]]).should == [1,2,[3,4]]
    end

    it "should leave hashes alone" do
      Schlep.serialize_message({ :one => { :two => 3 }}).should == ({ :one => { :two => 3 }})
    end

    it "should leave integers alone" do
      Schlep.serialize_message(123).should == 123
    end

    it "should leave floats alone" do
      Schlep.serialize_message(1.23).should == 1.23
    end
  end

  context "#timestamp" do
    it "should be a float" do
      Schlep.timestamp.should be_a Float
    end
  end

  # private

  context "#sanitize" do
    it "should strip whitespace" do
      Schlep.send(:sanitize, "test string").should == "teststring"
    end

    it "should strip newlines" do
      Schlep.send(:sanitize, "test\n").should == "test"
    end

    it "should replace special characters with a colon" do
      Schlep.send(:sanitize, "a:b/c^d$$e").should == "a:b:c:d:e"
    end

    it "should remove special characters at the beginning or end or a string" do
      Schlep.send(:sanitize, "$test$string$").should == "test:string"
    end

    it "should not replace periods" do
      Schlep.send(:sanitize, "a.b.c.d.e").should == "a.b.c.d.e"
    end
  end
end