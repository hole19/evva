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

  describe ".filter_platforms!" do
    def event(name, platforms, properties = {})
      Evva::AnalyticsEvent.new(name, properties, ["firebase"], platforms)
    end

    let(:everywhere) { event("everywhere", Evva::AnalyticsEvent::PLATFORMS) }
    let(:ios_only) { event("ios_only", ["ios"], { from_screen: "IosOnlyEnum" }) }
    let(:android_only) { event("android_only", ["android"], { from_screen: "AndroidOnlyEnum" }) }

    let(:events) { [everywhere, ios_only, android_only] }

    let(:enums) do
      [
        Evva::AnalyticsEnum.new("IosOnlyEnum", ["a"]),
        Evva::AnalyticsEnum.new("AndroidOnlyEnum", ["b"]),
        Evva::AnalyticsEnum.new("NeverReferenced", ["c"]),
      ]
    end

    let(:people) { [Evva::AnalyticsProperty.new("total_friends", "Int", [])] }

    let(:bundle) do
      { destinations: ["firebase"], events: events, people: people, enums: enums }
    end

    def enum_names
      bundle[:enums].map(&:enum_name)
    end

    def event_names
      bundle[:events].map(&:event_name)
    end

    context "when generating for iOS" do
      before { Evva.filter_platforms!(bundle, "iOS") }

      it "keeps events marked for every platform" do
        expect(event_names).to include("everywhere")
      end

      it "keeps iOS events" do
        expect(event_names).to include("ios_only")
      end

      it "drops Android events" do
        expect(event_names).not_to include("android_only")
      end
    end

    context "when generating for Android" do
      before { Evva.filter_platforms!(bundle, "Android") }

      it "keeps events marked for every platform" do
        expect(event_names).to include("everywhere")
      end

      it "keeps Android events" do
        expect(event_names).to include("android_only")
      end

      it "drops iOS events" do
        expect(event_names).not_to include("ios_only")
      end
    end

    context "when the configured type is in another casing" do
      before { Evva.filter_platforms!(bundle, "IOS") }

      it "filters all the same" do
        expect(event_names).to eq(["everywhere", "ios_only"])
      end
    end

    context "when the configured type is lowercase" do
      before { Evva.filter_platforms!(bundle, "android") }

      it "filters all the same" do
        expect(event_names).to eq(["everywhere", "android_only"])
      end
    end

    it "accounts for every event it was given" do
      events_in = bundle[:events].size
      Evva.filter_platforms!(bundle, "iOS")
      events_out = bundle[:events].size
      events_filtered = events.count { |e| !e.supports_platform?("ios") }

      expect(events_in).to eq(events_out + events_filtered)
    end

    context "when no event is filtered out" do
      let(:events) { [everywhere] }

      it "leaves the events untouched" do
        expect { Evva.filter_platforms!(bundle, "iOS") }.not_to change { bundle[:events] }
      end

      it "leaves the enums untouched, orphans included" do
        expect { Evva.filter_platforms!(bundle, "iOS") }.not_to change { enum_names }
      end

      it "logs nothing" do
        expect {
          Evva.filter_platforms!(bundle, "iOS")
        }.to not_change { Evva::Logger.summary[:info] }
      end
    end

    context "when the platform is not one we generate for" do
      before { Evva.filter_platforms!(bundle, "web") }

      it "filters nothing" do
        expect(event_names).to eq(["everywhere", "ios_only", "android_only"])
      end
    end

    describe "enum pruning" do
      it "prunes an enum whose only event was filtered out" do
        Evva.filter_platforms!(bundle, "ios")

        expect(enum_names).not_to include("AndroidOnlyEnum")
      end

      it "keeps an enum still referenced by a surviving event" do
        Evva.filter_platforms!(bundle, "ios")

        expect(enum_names).to include("IosOnlyEnum")
      end

      it "keeps an enum that was already unreferenced before filtering" do
        Evva.filter_platforms!(bundle, "ios")

        expect(enum_names).to include("NeverReferenced")
      end

      context "when a filtered event's enum is also referenced by a people property" do
        let(:people) do
          [Evva::AnalyticsProperty.new("wearable_platform", "AndroidOnlyEnum", [])]
        end

        it "keeps the enum" do
          Evva.filter_platforms!(bundle, "ios")

          expect(enum_names).to include("AndroidOnlyEnum")
        end
      end

      context "when the reference is optional" do
        let(:android_only) { event("android_only", ["android"], { from_screen: "AndroidOnlyEnum?" }) }
        let(:ios_only) { event("ios_only", ["ios"], { from_screen: "IosOnlyEnum?" }) }

        it "prunes the filtered platform's enum" do
          Evva.filter_platforms!(bundle, "ios")

          expect(enum_names).not_to include("AndroidOnlyEnum")
        end

        it "keeps the surviving platform's enum" do
          Evva.filter_platforms!(bundle, "ios")

          expect(enum_names).to include("IosOnlyEnum")
        end
      end
    end

    describe "logging" do
      subject(:messages) do
        logged = []
        allow(Evva::Logger).to receive(:info) { |msg| logged << msg }
        Evva.filter_platforms!(bundle, "ios")
        logged
      end

      it "names the filtered events" do
        expect(messages).to include("filtered 1 events (android_only)")
      end

      it "names the pruned enums" do
        expect(messages).to include("pruned 1 enums (AndroidOnlyEnum)")
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
