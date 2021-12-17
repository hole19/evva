describe Evva::SwiftGenerator do
  let(:generator) { described_class.new }

  describe '#events' do
    subject { generator.events(event_bundle, "") }

    let(:event_bundle) { [
      Evva::AnalyticsEvent.new('cp_page_view', {}, []),
      Evva::AnalyticsEvent.new('cp_page_view_a', { course_id: 'Long', course_name: 'String' }, []),
      Evva::AnalyticsEvent.new('cp_page_view_b', { course_id: 'Long', course_name: 'String', from_screen: 'CourseProfileSource' }, []),
      Evva::AnalyticsEvent.new('cp_page_view_c', { course_id: 'Long', course_name: 'String', from_screen: 'CourseProfileSource?' }, []),
      Evva::AnalyticsEvent.new('cp_page_view_d', { course_id: 'Long?', course_name: 'String' }, []),
    ] }

    let(:expected) {
<<-Swift
// This file was automatically generated by evva: https://github.com/hole19/evva

import Foundation

extension Analytics {
    struct EventData {
        let name: String
        let properties: [String: Any]?

        init(name: String, properties: [String: Any]? = nil) {
            self.name = name
            self.properties = properties
        }

        init(name: EventName, properties: [String: Any]? = nil) {
            self.init(name: name.rawValue, properties: properties)
        }
    }

    enum EventName: String {
        case cpPageView = "cp_page_view"
        case cpPageViewA = "cp_page_view_a"
        case cpPageViewB = "cp_page_view_b"
        case cpPageViewC = "cp_page_view_c"
        case cpPageViewD = "cp_page_view_d"
    }

    enum Event {
        case cpPageView
        case cpPageViewA(course_id: Int, course_name: String)
        case cpPageViewB(course_id: Int, course_name: String, from_screen: CourseProfileSource)
        case cpPageViewC(course_id: Int, course_name: String, from_screen: CourseProfileSource?)
        case cpPageViewD(course_id: Int?, course_name: String)

        var data: EventData {
            switch self {
            case .cpPageView:
                return EventData(name: .cpPageView)

            case .cpPageViewA(let course_id, let course_name):
                return EventData(name: .cpPageViewA, properties: [
                    "course_id": course_id as Any,
                    "course_name": course_name as Any ]
                )

            case .cpPageViewB(let course_id, let course_name, let from_screen):
                return EventData(name: .cpPageViewB, properties: [
                    "course_id": course_id as Any,
                    "course_name": course_name as Any,
                    "from_screen": from_screen.rawValue as Any ]
                )

            case .cpPageViewC(let course_id, let course_name, let from_screen):
                return EventData(name: .cpPageViewC, properties: [
                    "course_id": course_id as Any,
                    "course_name": course_name as Any,
                    "from_screen": from_screen?.rawValue as Any ]
                )

            case .cpPageViewD(let course_id, let course_name):
                return EventData(name: .cpPageViewD, properties: [
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
      Evva::AnalyticsEnum.new('CourseProfileSource', ['course_discovery', 'synced_courses']),
      Evva::AnalyticsEnum.new('PremiumFrom', ['Course Profile', 'Round Setup']),
    ] }

    let(:expected) {
<<-Swift
// This file was automatically generated by evva: https://github.com/hole19/evva

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

    let(:people_bundle) { [
      Evva::AnalyticsProperty.new('rounds_with_wear', 'String', []),
      Evva::AnalyticsProperty.new('wear_platform', 'WearableAppPlatform', []),
    ] }

    let(:expected) {
<<-Swift
// This file was automatically generated by evva: https://github.com/hole19/evva

import Foundation

extension Analytics {
    enum Property: String {
        case roundsWithWear = "rounds_with_wear"
        case wearPlatform = "wear_platform"
    }
}
Swift
    }

    it { should eq expected }
  end
end
