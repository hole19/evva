describe Evva::GoogleSheet do
  let(:sheet) { Evva::GoogleSheet.new(events_sheet, people_sheet, enum_sheet) }

  let(:events_sheet) { "https://wtvr1" }
  let(:people_sheet) { "https://wtvr2" }
  let(:enum_sheet) { "https://wtvr3" }
  let(:events_file) { File.read('spec/fixtures/sample_public_events.csv') }
  let(:people_file)  { File.read('spec/fixtures/sample_public_people_properties.csv') }
  let(:enum_file)  { File.read('spec/fixtures/sample_public_enums.csv') }

  before do
    stub_request(:get, events_sheet).to_return(status: 200, body: events_file, headers: {})
    stub_request(:get, people_sheet).to_return(status: 200, body: people_file, headers: {})
    stub_request(:get, enum_sheet).to_return(status: 200, body: enum_file, headers: {})
  end

  describe '#events' do
    subject(:events) { sheet.events }

    it do
      expect { events }.not_to raise_error
    end

    it 'returns an array with the corresponding events' do
      expected = [Evva::MixpanelEvent.new('cp_page_view', { course_id: 'Long', course_name: 'String' }),
                  Evva::MixpanelEvent.new('nav_feed_tap', {}),
                  Evva::MixpanelEvent.new('cp_view_scorecard', { course_id: 'Long', course_name: 'String' })]
      expect(events).to eq(expected)
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

  describe '#people_properties' do
    subject(:people_properties) { sheet.people_properties }

    it do
      expect { people_properties }.not_to raise_error
    end

    it 'returns an array with the corresponding events' do
      expect(people_properties).to eq [
        'rounds_with_wear',
        'total_friends'
      ]
    end
  end

  describe '#enum_classes' do
    subject(:enum_classes) { sheet.enum_classes }

    it do
      expect { enum_classes }.not_to raise_error
    end

    it 'returns an array with the corresponding events' do
      expect(enum_classes).to eq [
        Evva::MixpanelEnum.new('PageViewSourceScreen', ['course_discovery','synced_courses','nearby','deal']),
        Evva::MixpanelEnum.new('PremiumClickBuy', ['notes','hi_res_maps','whatever'])
      ]
    end
  end
end
