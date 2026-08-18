describe "filtering by platform end to end" do
  let(:events_url) { "https://wtvr1" }
  let(:people_url) { "https://wtvr2" }
  let(:enum_url) { "https://wtvr3" }

  let(:events_fixture) { "sample_public_events_with_platform.csv" }
  let(:enums_fixture) { "sample_public_enums_with_platform.csv" }

  before do
    stub_request(:get, events_url).to_return(status: 200, body: fixture(events_fixture))
    stub_request(:get, people_url).to_return(status: 200, body: fixture("sample_public_people_properties.csv"))
    stub_request(:get, enum_url).to_return(status: 200, body: fixture(enums_fixture))
  end

  def fixture(name)
    File.read("spec/fixtures/#{name}")
  end

  def unfiltered_bundle
    source = {
      type: "google_sheet",
      events_url: events_url,
      people_properties_url: people_url,
      enum_classes_url: enum_url
    }
    Evva.analytics_data(config: source)
  end

  def bundle_for(type)
    bundle = unfiltered_bundle
    Evva.filter_platforms!(bundle, type)
    bundle
  end

  def logged_while
    logged = []
    allow(Evva::Logger).to receive(:info) { |msg| logged << msg }
    yield
    logged
  end

  describe "for iOS" do
    let(:bundle) { bundle_for("iOS") }

    it "keeps the iOS and every-platform events" do
      expect(bundle[:events].map(&:event_name)).to eq(%w[
        cp_page_view
        ios_only_event
        both_listed_event
        mixed_case_event
        both_keyword_event
        wear_sync_event
      ])
    end

    it "accounts for every event it was given" do
      filtered = logged_while { bundle }.grep(/^filtered/).first.to_s[/\((.*)\)/, 1].to_s.split(", ")

      expect(bundle[:events].size + filtered.size).to eq(unfiltered_bundle[:events].size)
    end

    it "prunes the Android only enum and keeps the rest" do
      expect(bundle[:enums].map(&:enum_name)).to eq(%w[
        PageViewSourceScreen
        IosOnlyEnum
        SharedEnum
        WearableAppPlatform
      ])
    end
  end

  describe "for Android" do
    let(:bundle) { bundle_for("Android") }

    it "keeps the Android and every-platform events" do
      expect(bundle[:events].map(&:event_name)).to eq(%w[
        cp_page_view
        android_only_event
        both_listed_event
        both_keyword_event
      ])
    end

    it "prunes the iOS only enum" do
      expect(bundle[:enums].map(&:enum_name)).not_to include("IosOnlyEnum")
    end

    # wear_sync_event is iOS only and gets filtered here, but the
    # wearable_platform people property still references the enum.
    it "keeps an enum held only by a people property" do
      expect(bundle[:enums].map(&:enum_name)).to include("WearableAppPlatform")
    end

    it "keeps the enum no event ever referenced" do
      expect(bundle[:enums].map(&:enum_name)).to include("PageViewSourceScreen")
    end
  end

  # What protects the sheets that predate the column, the CORE Golf one included.
  # The generators are pure functions of the bundle and are untouched here, so a
  # bundle the filter left alone generates exactly what it generated before.
  describe "a sheet with no Platform column" do
    let(:events_fixture) { "sample_public_events.csv" }
    let(:enums_fixture) { "sample_public_enums.csv" }

    %w[iOS Android].each do |type|
      it "leaves the #{type} bundle untouched" do
        before_filtering = unfiltered_bundle
        after_filtering = bundle_for(type)

        expect(after_filtering[:events].map(&:event_name)).to eq(before_filtering[:events].map(&:event_name))
        expect(after_filtering[:enums].map(&:enum_name)).to eq(before_filtering[:enums].map(&:enum_name))
        expect(after_filtering[:people].map(&:property_name)).to eq(before_filtering[:people].map(&:property_name))
      end
    end

    it "keeps enums that no event references" do
      expect(bundle_for("iOS")[:enums].map(&:enum_name)).to eq(%w[PageViewSourceScreen PremiumClickBuy])
    end

    it "reports no filtering" do
      expect(logged_while { bundle_for("iOS") }.grep(/filtered|pruned/)).to be_empty
    end
  end
end
