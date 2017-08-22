describe Evva::Config do
  subject(:config) { Evva::Config.new(hash: hash) }

  let(:hash) { {
    type: "BisuOS",
    dictionary: {
      type:         "google_sheet",
      sheet_id:     "abc1234567890",
      keys_column:  "key_name"
    },
    out_path: "clear/path/to/event"
  } }

  context "when hash is missing params" do
    before { hash.delete(:type) }
    it { expect { config }.to raise_error /missing keys/i }
  end

  its(:to_h) { should eq(hash) }
  its(:type) { should eq("BisuOS") }
  its(:out_path) { should eq("clear/path/to/event") }

  describe "#dictionary" do
    subject(:dictionary) { config.dictionary }

    it { should eq({ type: "google_sheet", sheet_id: "abc1234567890", keys_column: "key_name" }) }

    context "when given an unknown type dictionary" do
      before { hash[:dictionary] = { type: "i_dunno" } }
      it { expect { config }.to raise_error /unknown dictionary type 'i_dunno'/i }
    end
  end
end
