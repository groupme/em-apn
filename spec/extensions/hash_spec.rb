require "spec_helper"

describe Hash do
  describe "stringify_keys!" do
    it "returns the hash" do
      {}.stringify_keys!.should eq({})
    end

    it "converts keys into strings" do
      hash = {
        :symbol => "value",
        1       => "value",
        []      => "value"
      }

      hash.stringify_keys!

      hash.keys.should =~ ["symbol", "1", "[]"]
    end

    it "leaves string keys untouched" do
      string = stub
      string.should_receive(:kind_of?).with(String).and_return(true)

      symbol = stub(to_s: "symbol")
      symbol.should_receive(:kind_of?).with(String).and_return(false)

      hash = {
        string => "value",
        symbol => "value"
      }

      hash.stringify_keys!

      hash.keys.should =~ ["symbol", string]
    end
  end
end
