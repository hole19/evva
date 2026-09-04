describe Evva::GoogleSheet do
  let(:sheet) { Evva::GoogleSheet.new(events_sheet, people_sheet, enum_sheet) }

  let(:events_sheet) { "https://wtvr1" }
  let(:people_sheet) { "https://wtvr2" }
  let(:enum_sheet) { "https://wtvr3" }
  let(:events_file) { File.read("spec/fixtures/sample_public_events.csv") }
  let(:people_file)  { File.read("spec/fixtures/sample_public_people_properties.csv") }
  let(:enum_file)  { File.read("spec/fixtures/sample_public_enums.csv") }

  before do
    stub_request(:get, events_sheet).to_return(status: 200, body: events_file, headers: {})
    stub_request(:get, people_sheet).to_return(status: 200, body: people_file, headers: {})
    stub_request(:get, enum_sheet).to_return(status: 200, body: enum_file, headers: {})
  end

  describe "#events" do
    subject(:events) { sheet.events }

    it do
      expect { events }.not_to raise_error
    end

    it "returns an array with the corresponding events" do
      expected = [
        Evva::AnalyticsEvent.new("cp_page_view", { course_id: "Long", course_name: "String" }, ["firebase", "custom destination"], nil),
        Evva::AnalyticsEvent.new("nav_feed_tap", {}, [], nil),
        Evva::AnalyticsEvent.new("cp_view_scorecard", { course_id: "Long", course_name: "String" }, ["custom destination"], nil),
        Evva::AnalyticsEvent.new("side_game_delete", { fromScreen: "SideGameFromScreen", round_group_creation_token: "String" }, ["firebase"], nil),
      ]
      expect(events).to eq(expected)
    end

    context "when the sheet has no Platform column" do
      it "leaves platforms as nil (unrestricted)" do
        expect(events.map(&:platforms)).to all(be_nil)
      end
    end

    context "when the sheet has a Platform column" do
      let(:events_file) { File.read("spec/fixtures/sample_public_events_with_platform.csv") }

      def platforms_for(event_name)
        events.find { |event| event.event_name == event_name }.platforms
      end

      it do
        expect { events }.not_to raise_error
      end

      it "reads the column by header name, whatever its position" do
        expect(events.map(&:event_name)).to eq(%w[
          cp_page_view
          ios_only_event
          android_only_event
          multi_platform_event
          mixed_case_event
          wear_sync_event
        ])
      end

      it "treats an empty cell as unrestricted" do
        expect(platforms_for("cp_page_view")).to be_nil
      end

      it "reads a single platform" do
        expect(platforms_for("ios_only_event")).to eq(["ios"])
        expect(platforms_for("android_only_event")).to eq(["android"])
      end

      it "reads a comma separated list of platforms" do
        expect(platforms_for("multi_platform_event")).to eq(["ios", "android"])
      end

      it "normalises casing" do
        expect(platforms_for("mixed_case_event")).to eq(["ios"])
      end
    end

    ["platform", "Platform ", " Platform", "PLATFORM", "pLaTfOrM"].each do |header|
      context "when the Platform header is written as #{header.inspect}" do
        let(:events_file) { %(Event Name,"#{header}"\nsome_event,Android\n) }

        it "still finds the column" do
          expect(events.first.platforms).to eq(["android"])
        end
      end
    end

    context "when there is no Platform column" do
      let(:events_file) { "Event Name,Event Destination\nsome_event,firebase\n" }

      it "says so, so that a mistyped header is not mistaken for a filter that ran" do
        logged = []
        allow(Evva::Logger).to receive(:info) { |msg| logged << msg }

        events

        expect(logged).to include(/No Platform column/)
      end
    end

    context "when the Platform column is present" do
      let(:events_file) { "Event Name,Platform\nsome_event,iOS\n" }

      it "does not report a missing column" do
        logged = []
        allow(Evva::Logger).to receive(:info) { |msg| logged << msg }

        events

        expect(logged).not_to include(/No Platform column/)
      end
    end

    context "when a platform cell is written in another casing" do
      let(:events_file) { "Event Name,Platform\nsome_event,  AnDrOiD  \n" }

      it "normalises it" do
        expect(events.first.platforms).to eq(["android"])
      end
    end

    context "when a platform cell repeats a platform" do
      let(:events_file) { "Event Name,Platform\nsome_event,\"ios,iOS\"\n" }

      it "does not duplicate it" do
        expect(events.first.platforms).to eq(["ios"])
      end
    end

    context "when a platform cell has an unknown token" do
      let(:events_file) { "Event Name,Platform\nsome_event,Windows\n" }

      it "stores it as-is (lowercased)" do
        expect(events.first.platforms).to eq(["windows"])
      end
    end

    context "when given an inexistent sheet" do
      before { stub_request(:get, events_sheet).to_return(status: 400, body: "Not Found", headers: {}) }

      it do
        expect { events }.to raise_error /Http Error/
      end
    end

    context "when url content is not CSV" do
      before { stub_request(:get, events_sheet).to_return(status: 200, body: "{\"asdsa\": \"This is a json\"}", headers: {}) }

      it do
        expect { events }.to raise_error /Cannot parse. Expected CSV/
      end
    end
  end

  describe "#people_properties" do
    subject(:people_properties) { sheet.people_properties }

    it do
      expect { people_properties }.not_to raise_error
    end

    it "returns an array with the corresponding events" do
      expect(people_properties).to eq [
        Evva::AnalyticsProperty.new("rounds_with_wear", "String", ["firebase", "custom destination"]),
        Evva::AnalyticsProperty.new("total_friends", "Int", []),
        Evva::AnalyticsProperty.new("wearable_platform", "WearableAppPlatform", ["firebase"]),
      ]
    end
  end

  describe "#enum_classes" do
    subject(:enum_classes) { sheet.enum_classes }

    it do
      expect { enum_classes }.not_to raise_error
    end

    it "returns an array with the corresponding events" do
      expect(enum_classes).to eq [
        Evva::AnalyticsEnum.new("PageViewSourceScreen", ["course_discovery","synced_courses","nearby","deal"]),
        Evva::AnalyticsEnum.new("PremiumClickBuy", ["notes","hi_res_maps","whatever"])
      ]
    end
  end

  describe "#destinations" do
    subject(:destinations) { sheet.destinations }

    it do
      expect { destinations }.not_to raise_error
    end

    it "returns an array with the corresponding events" do
      expect(destinations).to eq [
        "firebase",
        "custom destination",
      ]
    end
  end
end
