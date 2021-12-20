describe Evva::Config do
  subject(:config) { Evva::Config.new(hash: hash) }

  let(:hash) do
    {
      type: 'EvvaOS',
      data_source: {
        type: 'google_sheet',
        events_url: 'https://events.csv',
        people_properties_url: 'https://people_properties.csv',
        enum_classes_url: 'https://enum_classes.csv',
      },
      out_path: 'clear/path/to/event',
      event_file_name: 'event/file/name',
      event_enum_file_name: 'event/enum/file',
      people_file_name: 'people/file/name',
      people_enum_file_name: 'people/enum/file/name',
      platforms_file_name: 'platforms/file/name',
      package_name: 'com.package.name.analytics',
    }
  end

  context 'when hash is missing params' do
    before { hash.delete(:type) }
    it { expect { config }.to raise_error /missing keys/i }
  end

  its(:to_h) { should eq(hash) }
  its(:type) { should eq('EvvaOS') }
  its(:out_path) { should eq('clear/path/to/event') }
  its(:event_file_name) { should eq('event/file/name') }
  its(:event_enum_file_name) { should eq 'event/enum/file' }
  its(:people_file_name) { should eq('people/file/name') }
  its(:people_enum_file_name) { should eq('people/enum/file/name') }
  its(:platforms_file_name) { should eq 'platforms/file/name' }
  its(:package_name) { should eq 'com.package.name.analytics' }

  describe '#data_source' do
    subject(:data_source) { config.data_source }

    it { should eq(type: 'google_sheet', events_url: 'https://events.csv', people_properties_url: 'https://people_properties.csv', enum_classes_url: 'https://enum_classes.csv') }

    context 'when given an unknown type data source' do
      before { hash[:data_source] = { type: 'i_dunno' } }
      it { expect { config }.to raise_error /unknown data source type 'i_dunno'/i }
    end
  end
end
