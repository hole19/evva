describe Evva do
  subject(:run) { Evva.run([]) }

  context "when there is a config.yml file" do
    let(:file) { File.open("spec/fixtures/test.yml") }

    before do
      allow_any_instance_of(Evva::FileReader).to receive(:open_file).and_return(file)
      allow_any_instance_of(Evva::GoogleSheet).to receive(:events).and_return([])
      allow_any_instance_of(Evva::GoogleSheet).to receive(:people_properties).and_return([])
      allow_any_instance_of(Evva::GoogleSheet).to receive(:enum_classes).and_return([])
      allow_any_instance_of(Evva::GoogleSheet).to receive(:destinations).and_return([])
      allow(Evva).to receive(:write_to_file)
    end

    it { expect { run }.not_to raise_error }

    it "logs an error" do
      expect {
        run
      }.to not_change { Evva::Logger.summary[:warn] }
       .and not_change { Evva::Logger.summary[:error] }
    end
  end

  describe ".filter_destinations!" do
    let(:bundle) do
      {
        destinations: ["firebase", "mixpanel"],
        events: [Evva::AnalyticsEvent.new("test_event", {}, ["firebase", "mixpanel"])],
        people: [Evva::AnalyticsProperty.new("test_prop", "String", ["firebase", "mixpanel"])],
      }
    end

    context "when excluding a destination" do
      before { Evva.filter_destinations!(bundle, ["firebase"]) }

      it "removes it from the destinations list" do
        expect(bundle[:destinations]).to eq(["mixpanel"])
      end

      it "removes it from event destinations" do
        expect(bundle[:events].first.destinations).to eq(["mixpanel"])
      end

      it "removes it from people property destinations" do
        expect(bundle[:people].first.destinations).to eq(["mixpanel"])
      end
    end

    context "when exclude list is empty" do
      before { Evva.filter_destinations!(bundle, []) }

      it "does not change anything" do
        expect(bundle[:destinations]).to eq(["firebase", "mixpanel"])
      end
    end
  end

  context "when generic.yml does not exist locally" do
    let(:error) { "Could not open yml file" }
    before do
      allow_any_instance_of(Evva::FileReader).to receive(:open_file).and_return(false)
    end
    it { expect { run }.to_not raise_error }

    it "logs an error" do
      expect { run }.to not_change { Evva::Logger.summary[:warn] }
                    .and change { Evva::Logger.summary[:error] }.by(1)
    end
  end
end
