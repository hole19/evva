describe Evva::Config do
  subject(:config) { Evva::Config.new(hash: hash) }

  let(:hash) { {
    type: "EvvaOS",
    data_source: {
      type:         "google_sheet",
      sheet_id:     "abc1234567890"
    },
    out_path: "clear/path/to/event",
    event_file_name: "event/file/name",
    people_file_name: "people/file/name"
  } }

  context "when hash is missing params" do
    before { hash.delete(:type) }
    it { expect { config }.to raise_error /missing keys/i }
  end

  its(:to_h) { should eq(hash) }
  its(:type) { should eq("EvvaOS") }
  its(:out_path) { should eq("clear/path/to/event") }
  its(:event_file_name) { should eq("event/file/name") }
  its(:people_file_name) { should eq("people/file/name") }

  describe "#data_source" do
    subject(:data_source) { config.data_source }

    it { should eq({ type: "google_sheet", sheet_id: "abc1234567890" }) }

    context "when given an unknown type data source" do
      before { hash[:data_source] = { type: "i_dunno" } }
      it { expect { config }.to raise_error /unknown data source type 'i_dunno'/i }
    end
  end
end
