describe Evva::SwiftGenerator do
  let(:generator) { described_class.new }

  def trim_spaces(str)
      str.gsub(/^[ \t]+/, '')
         .gsub(/[ \t]+$/, '')
  end

  describe '#events' do
    subject { trim_spaces(generator.events(event_bundle, "")) }
    let(:event_bundle) {
      [Evva::MixpanelEvent.new('nav_feed_tap', []),
       Evva::MixpanelEvent.new('cp_page_view', ['course_id:Long'],['course_name:String?'])]
    }
    let(:expected) { <<-Swift
        import CoreLocation
        import Foundation
        import SharedCode

        class MixpanelHelper: NSObject {
          enum Event {
            case trackNavFeedTap
            case trackCpPageView(course_id: Long, course_name: String?)
          }

          private var data: EventData {
            switch self {

            case .trackNavFeedTap
              return EventData(name:"nav_feed_tap")

            case .trackCpPageView(let course_id, let course_name):
              return EventData(name:"cp_page_view", properties: ["course_id": course_id, "course_name": course_name])
          }
        }
      Swift
    }
    it { should eq trim_spaces(expected) }
  end

  describe '#process_arguments' do
    context "with optional arguments" do
      let(:properties) { 'course_id:Long,course_name:String,from_screen: CourseProfileSource?' }

      it 'processes the arguments looking for special properties' do
        expected = '"course_id": course_id, "course_name": course_name, "from_screen": from_screen.rawValue'
        expect(generator.process_arguments(properties)).to eq expected
      end
    end

    context "without optional arguments" do
      let(:properties) { 'course_id:Long,course_name:String,from_screen: CourseProfileSource' }

      it 'processes the arguments looking for special properties' do
        expected = '"course_id": course_id, "course_name": course_name, "from_screen": from_screen.rawValue'
        expect(generator.process_arguments(properties)).to eq expected
      end
    end
  end

  describe '#special_property_enum' do
    subject { trim_spaces(generator.special_property_enum(enum)) }
    let(:enum) { Evva::MixpanelEnum.new('CourseProfileSource', 'course_discovery,synced_courses') }
    let(:expected) { <<-Swift
        import Foundation

        enum CourseProfileSource: String {
          case course_discovery = "course_discovery"
          case synced_courses = "synced_courses"
        }
      Swift
     }

    it { should eq trim_spaces(expected) }
  end

  describe "#people_properties" do
    subject { trim_spaces(generator.people_properties(people_bundle)) }
    let(:people_bundle) { ['rounds_with_wear', 'friends_from_facebook'] }
    let(:expected) { <<-Swift
      fileprivate enum Counter: String {
        case RoundsWithWear = "rounds_with_wear"
        case FriendsFromFacebook = "friends_from_facebook"

        func increment(times: Int = 1) {
          MixpanelAPI.instance.incrementCounter(rawValue, times: times)
        }
      }
      Swift
    }

    it { should eq trim_spaces(expected) }
  end
end
