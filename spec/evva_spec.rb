describe Evva do
  subject(:run) { Evva.run([]) }

  context "when there is a config.yml file" do
    let(:file) { File.open("spec/fixtures/test.yml") }

    before do
      allow_any_instance_of(Evva::FileReader).to receive(:open_file).and_return(file)
      allow_any_instance_of(Evva::GoogleSheet).to receive(:events).and_return(
        [Evva::AnalyticsEvent.new('trackEvent',[])])

      allow_any_instance_of(Evva::GoogleSheet).to receive(:people_properties).and_return([])
      allow_any_instance_of(Evva::GoogleSheet).to receive(:enum_classes).and_return([])

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