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
       Evva::MixpanelEvent.new('cp_page_view', {'course_id' => 'Long' , 'course_name' => 'String?' })]
    }
    let(:expected) { <<-Swift

        import Foundation

        extension Analytics {

          enum Event {

            case navFeedTap
            case cpPageView(course_id: Int, course_name: String?)

            var data: EventData {
              switch self {
              case .navFeedTap:
                return EventData(name: "nav_feed_tap")

              case .cpPageView(let course_id, let course_name):
                return EventData(name: "cp_page_view", properties: [
                  "course_id": course_id as Any,
                  "course_name": course_name as Any ]
              )

              }
            }

          }

        }
      Swift
    }
    it { should eq trim_spaces(expected) }
  end

  describe '#special_property_enum' do
    subject { trim_spaces(generator.special_property_enum(enum)) }
    let(:enum) { Evva::MixpanelEnum.new('CourseProfileSource', ['course_discovery', 'synced_courses']) }
    let(:expected) { <<-Swift

        import Foundation

        extension Analytics {

          enum CourseProfileSource: String {
            case course_discovery = "course_discovery"
            case synced_courses = "synced_courses"
          }

        }
      Swift
     }

    it { should eq trim_spaces(expected) }
  end

  describe "#people_properties" do
    subject { trim_spaces(generator.people_properties(people_bundle, "")) }
    let(:people_bundle) { ['rounds_with_wear', 'friends_from_facebook'] }
    let(:expected) { <<-Swift

        import Foundation

        extension Analytics {

          enum Property: String {
            case roundsWithWear = "rounds_with_wear"
            case friendsFromFacebook = "friends_from_facebook"
        }

      }
      Swift
    }

    it { should eq trim_spaces(expected) }
  end
end
