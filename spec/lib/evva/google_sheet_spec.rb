describe Evva::GoogleSheet do
  let(:sheet) { Evva::GoogleSheet.new(sheet_id) }
  let(:sheet_id) { "abc1234567890" }
  let(:url_info)  { "https://spreadsheets.google.com/feeds/worksheets/#{sheet_id}/public/full" }
  let(:url_sheet) { "https://spreadsheets.google.com/feeds/list/#{sheet_id}/od6/public/full" }
  let(:enum_sheet) { "https://spreadsheets.google.com/feeds/list/#{sheet_id}/osju1vh/public/full" }
  let(:people_sheet) { "https://spreadsheets.google.com/feeds/list/#{sheet_id}/ojyi830/public/full" }
  let(:file_info)  { File.read("spec/fixtures/sample_public_info.html") }
  let(:file_sheet) { File.read("spec/fixtures/sample_public_sheet.html") }
  let(:enum_file)  { File.read("spec/fixtures/sample_public_enums.html") }
  let(:people_file)  { File.read("spec/fixtures/sample_public_people_properties.html") } 

  describe "#events" do
    subject(:events) { sheet.events }
    before do
      stub_request(:get, url_info).to_return(:status => 200, :body => file_info, :headers => {})
      stub_request(:get, url_sheet).to_return(:status => 200, :body => file_sheet, :headers => {})
    end

    context "when given a valid sheet" do

      it do
        expect { events }.not_to raise_error
      end

      it "returns an array with the corresponding events" do
        expected = [Evva::MixpanelEvent.new('trackCpPageView','cp_page_view',['course_id:Long,course_name:String']),
        Evva::MixpanelEvent.new('trackNavFeedTap','nav_feed_tap',[]),
        Evva::MixpanelEvent.new('trackCpViewScorecard','cp_view_scorecard',['course_id:Long,course_name:String'])]
        expect(events).to eq(expected)
      end 
    end

    context "when given an inexistent sheet" do
      before { stub_request(:get, url_info).to_return(:status => 400, :body => "Not Found", :headers => {}) }

      it do
        expect { events }.to raise_error /Cannot access sheet/
      end
    end

    context "when given a private sheet" do
      before { stub_request(:get, url_info).to_return(:status => 302, :body => "<HTML></HTML>", :headers => {}) }

      it do
        expect { events }.to raise_error /Cannot access sheet/
      end
    end

    context "when url content is not XML" do
      before { stub_request(:get, url_info).to_return(:status => 200, :body => "This is not XML; { this: \"is json\" }", :headers => {}) }

      it do
        expect { events }.to raise_error /Cannot parse. Expected XML/
      end
    end
  end

  describe "#enum_classes" do
    subject(:enum_classes) { sheet.enum_classes }
    let(:expected_enum) { [
      Evva::MixpanelEnum.new('PageViewSourceScreen','course_discovery,synced_courses,nearby,deal'),
      Evva::MixpanelEnum.new('PremiumClickBuy', 'notes,hi_res_maps,whatever')] }

    context "when given a valid sheet" do
      before do
        stub_request(:get, url_info).to_return(:status => 200, :body => file_info, :headers => {})
        stub_request(:get, enum_sheet).to_return(:status => 200, :body => enum_file, :headers => {})
      end

      it do
        expect { enum_classes }.not_to raise_error
      end

      it "returns an array with the corresponding events" do
        expect(enum_classes).to eq expected_enum 
      end 
    end   
  end

  describe "#people_properties" do
    subject(:people_properties) { sheet.people_properties }
    let(:expected_people_properties) { [ 
     Evva::MixpanelProperty.new('roundsWithWear', 'rounds_with_wear'),
     Evva::MixpanelProperty.new('totalFriends', 'total_friends')
    ]}

      context "when given a valid sheet" do
      before do
        stub_request(:get, url_info).to_return(:status => 200, :body => file_info, :headers => {})
        stub_request(:get, people_sheet).to_return(:status => 200, :body => people_file, :headers => {})
      end

      it do
        expect { people_properties }.not_to raise_error
      end

      it "returns an array with the corresponding events" do
        expect(people_properties).to eq expected_people_properties 
      end 
    end   
  end
end