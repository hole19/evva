describe Evva::Config do
  subject(:config) { Evva::Config.new(hash: hash) }

  let(:hash) do
    {
      type: "EvvaOS",
      data_source: {
        type: "google_sheet",
        events_url: "https://events.csv",
        people_properties_url: "https://people_properties.csv",
        enum_classes_url: "https://enum_classes.csv",
      },
      out_path: "clear/path/to/event",
      event_file_name: "event/file/name",
      event_enum_file_name: "event/enum/file",
      people_file_name: "people/file/name",
      people_enum_file_name: "people/enum/file/name",
      destinations_file_name: "destinations/file/name",
      package_name: "com.package.name.analytics",
    }
  end

  context "when hash is missing params" do
    before { hash.delete(:type) }
    it { expect { config }.to raise_error /missing keys/i }
  end

  its(:to_h) { should eq(hash) }
  its(:type) { should eq("EvvaOS") }
  its(:out_path) { should eq("clear/path/to/event") }
  its(:event_file_name) { should eq("event/file/name") }
  its(:event_enum_file_name) { should eq "event/enum/file" }
  its(:people_file_name) { should eq("people/file/name") }
  its(:people_enum_file_name) { should eq("people/enum/file/name") }
  its(:destinations_file_name) { should eq "destinations/file/name" }
  its(:package_name) { should eq "com.package.name.analytics" }
  its(:swift_public?) { should eq(false) }

  describe "#data_source" do
    subject(:data_source) { config.data_source }

    it { should eq(type: "google_sheet", events_url: "https://events.csv", people_properties_url: "https://people_properties.csv", enum_classes_url: "https://enum_classes.csv") }

    context "when given an unknown type data source" do
      before { hash[:data_source] = { type: "i_dunno" } }
      it { expect { config }.to raise_error /unknown data source type 'i_dunno'/i }
    end
  end

  describe "#exclude_destinations" do
    context "when not set" do
      its(:exclude_destinations) { should eq([]) }
    end

    context "when set to an array" do
      before { hash[:exclude_destinations] = ["firebase"] }

      its(:exclude_destinations) { should eq(["firebase"]) }
    end

    context "when not an array" do
      before { hash[:exclude_destinations] = "firebase" }

      it { expect { config }.to raise_error(ArgumentError, /Expected Array, got String/) }
    end
  end

  describe "#swift_public?" do
    context "when swift_public is true" do
      before { hash[:swift_public] = true }

      its(:swift_public?) { should eq(true) }
    end

    context "when swift_public is false" do
      before { hash[:swift_public] = false }

      its(:swift_public?) { should eq(false) }
    end

    context "when swift_public is not a boolean" do
      before { hash[:swift_public] = "yes" }

      it { expect { config }.to raise_error(ArgumentError, "swift_public must be true or false") }
    end
  end
end
