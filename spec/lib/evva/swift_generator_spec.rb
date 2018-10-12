describe Evva::SwiftGenerator do
  let(:generator) { described_class.new }

  describe '#events' do
    subject { generator.events(event_bundle, "") }

    let(:event_bundle) { [
      Evva::MixpanelEvent.new('cp_page_view'),
      Evva::MixpanelEvent.new('cp_page_view_a', { course_id: 'Long', course_name: 'String' }),
      Evva::MixpanelEvent.new('cp_page_view_b', { course_id: 'Long', course_name: 'String', from_screen: 'CourseProfileSource' }),
      Evva::MixpanelEvent.new('cp_page_view_c', { course_id: 'Long', course_name: 'String', from_screen: 'CourseProfileSource?' }),
      Evva::MixpanelEvent.new('cp_page_view_d', { course_id: 'Long?', course_name: 'String' })
    ] }

    let(:expected) {
<<-Swift
import Foundation

extension Analytics {

    enum Event {
        case cpPageView
        case cpPageViewA(course_id: Int, course_name: String)
        case cpPageViewB(course_id: Int, course_name: String, from_screen: CourseProfileSource)
        case cpPageViewC(course_id: Int, course_name: String, from_screen: CourseProfileSource?)
        case cpPageViewD(course_id: Int?, course_name: String)

        var data: EventData {
            switch self {
            case .cpPageView:
                return EventData(name: "cp_page_view")

            case .cpPageViewA(let course_id, let course_name):
                return EventData(name: "cp_page_view_a", properties: [
                    "course_id": course_id as Any,
                    "course_name": course_name as Any ]
                )

            case .cpPageViewB(let course_id, let course_name, let from_screen):
                return EventData(name: "cp_page_view_b", properties: [
                    "course_id": course_id as Any,
                    "course_name": course_name as Any,
                    "from_screen": from_screen.rawValue as Any ]
                )

            case .cpPageViewC(let course_id, let course_name, let from_screen):
                return EventData(name: "cp_page_view_c", properties: [
                    "course_id": course_id as Any,
                    "course_name": course_name as Any,
                    "from_screen": from_screen?.rawValue as Any ]
                )

            case .cpPageViewD(let course_id, let course_name):
                return EventData(name: "cp_page_view_d", properties: [
                    "course_id": course_id as Any,
                    "course_name": course_name as Any ]
                )
            }
        }
    }
}
Swift
    }

    it { should eq expected }
  end

  describe '#special_property_enums' do
    subject { generator.special_property_enums(enums) }

    let(:enums) { [
      Evva::MixpanelEnum.new('CourseProfileSource', ['course_discovery', 'synced_courses']),
      Evva::MixpanelEnum.new('PremiumFrom', ['Course Profile', 'Round Setup'])
    ] }

    let(:expected) {
<<-Swift
import Foundation

extension Analytics {

    enum CourseProfileSource: String {
        case courseDiscovery = "course_discovery"
        case syncedCourses = "synced_courses"
    }

    enum PremiumFrom: String {
        case courseProfile = "Course Profile"
        case roundSetup = "Round Setup"
    }
}
Swift
    }

    it { should eq expected }
  end

  describe "#people_properties" do
    subject { generator.people_properties(people_bundle, "") }

    let(:people_bundle) { ['rounds_with_wear', 'friends_from_facebook'] }

    let(:expected) {
<<-Swift
import Foundation

extension Analytics {

    enum Property: String {
        case roundsWithWear = "rounds_with_wear"
        case friendsFromFacebook = "friends_from_facebook"
    }
}
Swift
    }

    it { should eq expected }
  end
end
