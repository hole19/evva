require "open3"

describe Evva::CsvSource do
  let(:sheet) { Evva::CsvSource.new(events_sheet, people_sheet, enum_sheet) }

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

  describe "auth token in sheet URLs" do
    let(:events_sheet) { "https://example.com/export/events.csv?token=evv_secret" }
    let(:people_sheet) { "https://example.com/export/people.csv?token=evv_secret" }
    let(:enum_sheet) { "https://example.com/export/enums.csv?token=evv_secret" }
    let(:logged) { [] }

    before do
      allow(Evva::Logger).to receive(:info) { |msg| logged << msg }
    end

    it "does not log the token or credentials when downloading" do
      sheet.events
      sheet.people_properties
      sheet.enum_classes

      expect(logged).to include("Downloading events sheet from https://example.com/export/events.csv")
      expect(logged.join("\n")).not_to match(/evv_secret|token=/)
    end

    context "when the response is not valid CSV" do
      let(:events_file) { "\"unterminated" }

      it "does not include the token in the error" do
        expect { sheet.events }.to raise_error(RuntimeError) { |e|
          expect(e.message).to include("https://example.com/export/events.csv")
          expect(e.message).not_to match(/evv_secret|token=/)
        }
      end
    end
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

    context "when list cells use line breaks, as exported by Google Sheets" do
      let(:events_file) { File.read("spec/fixtures/sample_public_events_multiline.csv") }

      it "reads each multi-line cell as one field and parses it like the comma separated sheet" do
        comma_separated = Evva::CsvSource.new(events_sheet, people_sheet, enum_sheet)
        stub_request(:get, events_sheet).to_return(status: 200, body: File.read("spec/fixtures/sample_public_events.csv"))
        expected = comma_separated.events

        stub_request(:get, events_sheet).to_return(status: 200, body: events_file)
        expect(events).to eq(expected)
      end
    end

    describe "list cells" do
      let(:events_file) { %(Event Name,Event Properties,Event Destination\nsome_event,"#{properties}","#{destinations}"\n) }
      let(:properties) { "a:Int,b:String?" }
      let(:destinations) { "mixpanel,braze" }

      {
        "comma separated" => "a:Int,b:String?",
        "one per line" => "a:Int\nb:String?",
        "one per line with CRLF" => "a:Int\r\nb:String?",
        "one per line with CR" => "a:Int\rb:String?",
        "mixed commas and line breaks" => "a:Int,\nb:String?",
        "a trailing comma" => "a:Int,b:String?,",
        "a trailing line break" => "a:Int\nb:String?\n",
        "blank lines between items" => "a:Int\n\n\nb:String?",
        "spaces around separators and colons" => " a : Int ,\n  b: String? ",
      }.each do |description, cell|
        context "with event properties written with #{description}" do
          let(:properties) { cell }

          it "parses the same properties" do
            expect(events.first.properties).to eq(a: "Int", b: "String?")
          end
        end
      end

      {
        "comma separated" => "mixpanel,braze",
        "with a space after each comma" => "mixpanel, braze",
        "one per line" => "mixpanel\nbraze",
        "a trailing comma" => "mixpanel,braze,",
      }.each do |description, cell|
        context "with event destinations written #{description}" do
          let(:destinations) { cell }

          it "parses the same destinations" do
            expect(events.first.destinations).to eq(["mixpanel", "braze"])
          end
        end
      end

      context "with empty cells" do
        let(:events_file) { "Event Name,Event Properties,Event Destination\nsome_event,,\n" }

        it "has no properties and no destinations" do
          expect(events.first.properties).to eq({})
          expect(events.first.destinations).to eq([])
        end
      end
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

  describe "#people_properties with spaces in the destination cell" do
    let(:people_file) { File.read("spec/fixtures/sample_public_people_properties_spaced.csv") }

    it "trims the space after each comma" do
      expect(sheet.people_properties.first.destinations).to eq(["firebase", "custom destination"])
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

    context "when values are written one per line, as exported by Google Sheets" do
      let(:enum_file) { File.read("spec/fixtures/sample_public_enums_multiline.csv") }

      it "parses the same values as the comma separated sheet" do
        expect(enum_classes.map(&:values)).to eq [
          ["course_discovery", "synced_courses", "nearby", "deal"],
          ["notes", "hi_res_maps", "whatever"],
        ]
      end
    end

    describe "a Possible Values cell" do
      let(:enum_file) { %(Enum Name,Possible Values\nSomeEnum,"#{values}"\n) }

      {
        "comma separated" => "a,b",
        "one per line" => "a\nb",
        "one per line with CRLF" => "a\r\nb",
        "mixed commas and line breaks" => "a,\nb",
        "a trailing comma" => "a,b,",
        "a trailing line break" => "a\nb\n",
        "blank lines between values" => "a\n\nb",
        "spaces around separators" => " a ,\n b ",
      }.each do |description, cell|
        context "written #{description}" do
          let(:values) { cell }

          it "parses the same values" do
            expect(enum_classes.first.values).to eq(["a", "b"])
          end
        end
      end

      context "with spaces inside a value" do
        let(:values) { "main app,No Scoring" }

        it "keeps them" do
          expect(enum_classes.first.values).to eq(["main app", "No Scoring"])
        end
      end

      ["", ",", "\n\n", " , "].each do |cell|
        context "with no values (#{cell.inspect})" do
          let(:values) { cell }

          it "stops with an error naming the enum, instead of generating an enum Swift cannot compile" do
            expect { enum_classes }.to raise_error("Enum SomeEnum has no Possible Values")
          end
        end
      end
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

describe "CSV data source compatibility" do
  let(:urls) { { events_url: "https://wtvr1", people_properties_url: "https://wtvr2", enum_classes_url: "https://wtvr3" } }

  before do
    stub_request(:get, urls[:events_url]).to_return(status: 200, body: File.read("spec/fixtures/sample_public_events.csv"))
    stub_request(:get, urls[:people_properties_url]).to_return(status: 200, body: File.read("spec/fixtures/sample_public_people_properties.csv"))
    stub_request(:get, urls[:enum_classes_url]).to_return(status: 200, body: File.read("spec/fixtures/sample_public_enums.csv"))
  end

  it "keeps Evva::GoogleSheet as an alias of Evva::CsvSource" do
    expect(Evva::GoogleSheet).to equal(Evva::CsvSource)
  end

  # Run in a fresh process so nothing the suite already loaded can hide a
  # missing file.
  it "still loads through the former require path" do
    script = 'require "evva/google_sheet"; exit(Evva::GoogleSheet.equal?(Evva::CsvSource) ? 0 : 1)'
    output, status = Open3.capture2e(RbConfig.ruby, "-Ilib", "-e", script)
    expect(status).to be_success, output
  end

  it "reads the same data for the legacy 'google_sheet' type as for 'csv'" do
    csv = Evva.analytics_data(config: urls.merge(type: "csv"))
    legacy = Evva.analytics_data(config: urls.merge(type: "google_sheet"))
    expect(legacy[:events]).to eq(csv[:events])
    expect(csv[:events]).not_to be_empty
  end
end
