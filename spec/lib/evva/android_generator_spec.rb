describe Evva::AndroidGenerator do
  let(:generator) { described_class.new }

  def trim_spaces(str)
      str.gsub(/^[ \t]+/, '')
         .gsub(/[ \t]+$/, '')
  end

  describe '#kotlin_function' do
    subject { trim_spaces(generator.kotlin_function(event)) }

    context 'when the event has no properties' do
      let(:event) { Evva::MixpanelEvent.new('nav_feed_tap', {}) }
      let(:expected) { <<-Kotlin
        open fun trackNavFeedTap() {
          mixpanelMask.trackEvent(MixpanelEvent.NAV_FEED_TAP)
        }
        Kotlin
      }
      it { should eq trim_spaces(expected) }
    end

    context 'event has properties' do
      let(:event) { Evva::MixpanelEvent.new('cp_page_view', { course_id: 'Long', course_name: 'String' }) }
      let(:expected) { <<-Kotlin
        open fun trackCpPageView(course_id: Long, course_name: String) {
          val properties = JSONObject().apply {
            put("course_id", course_id)
            put("course_name", course_name)
          }
          mixpanelMask.trackEvent(MixpanelEvent.CP_PAGE_VIEW, properties)
        }
        Kotlin
      }
      it { should eq trim_spaces(expected) }
    end

    context 'event has special properties' do
      let(:event) { Evva::MixpanelEvent.new('cp_page_view', { course_id: 'Long', course_name: 'String', from_screen: 'CourseProfileSource' }) }
      let(:expected) { <<-Kotlin
        open fun trackCpPageView(course_id: Long, course_name: String, from_screen: CourseProfileSource) {
          val properties = JSONObject().apply {
            put("course_id", course_id)
            put("course_name", course_name)
            put("from_screen", from_screen.key)
          }
          mixpanelMask.trackEvent(MixpanelEvent.CP_PAGE_VIEW, properties)
        }
        Kotlin
      }
      it { should eq trim_spaces(expected) }
    end

    context 'event has optional properties' do
      let(:event) { Evva::MixpanelEvent.new('cp_page_view', { course_id: 'Long', course_name: 'String', from_screen: 'CourseProfileSource?' }) }
      let(:expected) { <<-Kotlin
        open fun trackCpPageView(course_id: Long, course_name: String, from_screen: CourseProfileSource?) {
          val properties = JSONObject().apply {
            put("course_id", course_id)
            put("course_name", course_name)
            from_screen?.let { put("from_screen", it.key) }
          }
          mixpanelMask.trackEvent(MixpanelEvent.CP_PAGE_VIEW, properties)
        }
        Kotlin
      }
      it { should eq trim_spaces(expected) }
    end

    context 'event has optional but not special properties' do
      let(:event) { Evva::MixpanelEvent.new('cp_page_view', { course_id: 'Long?', course_name: 'String' }) }
      let(:expected) { <<-Kotlin
        open fun trackCpPageView(course_id: Long?, course_name: String) {
          val properties = JSONObject().apply {
            course_id?.let { put("course_id", it) }
            put("course_name", course_name)
          }
          mixpanelMask.trackEvent(MixpanelEvent.CP_PAGE_VIEW, properties)
        }
        Kotlin
      }
      it { should eq trim_spaces(expected) }
    end
  end

  describe '#special_property_enum' do
    subject { trim_spaces(generator.special_property_enum(enum)) }
    let(:enum) { Evva::MixpanelEnum.new('CourseProfileSource', ['course_discovery','synced_courses']) }
    let(:expected) { <<-Kotlin
      package com.hole19golf.hole19.analytics

      enum class CourseProfileSource(val key: String) {
        COURSE_DISCOVERY("course_discovery"),
        SYNCED_COURSES("synced_courses")
      }
      Kotlin
     }
    it { should eq trim_spaces(expected) }
  end

  describe '#event_enum' do
    subject { trim_spaces(generator.event_enum(event_bundle)) }
    let(:event_bundle) { [
      Evva::MixpanelEvent.new('nav_feed_tap', {}),
      Evva::MixpanelEvent.new('nav_performance_tap', {})
      ] }
    let(:expected) { <<-Kotlin
      package com.hole19golf.hole19.analytics
      import com.hole19golf.hole19.analytics.Event

      enum class MixpanelEvent(override val key: String) : Event {
        NAV_FEED_TAP("nav_feed_tap"),
        NAV_PERFORMANCE_TAP("nav_performance_tap")
      }
      Kotlin
     }
    it { should eq trim_spaces(expected) }
  end

  describe '#people_properties' do
    subject { trim_spaces(generator.people_properties(people_bundle)) }
    let(:people_bundle) { ['rounds_with_wear', 'friends_from_facebook'] }
    let(:expected) { <<-Kotlin
      package com.hole19golf.hole19.analytics
      import com.hole19golf.hole19.analytics.Event

      enum class MixpanelProperties(val key: String) {
        ROUNDS_WITH_WEAR("rounds_with_wear"),
        FRIENDS_FROM_FACEBOOK("friends_from_facebook");
      }
      Kotlin
    }
    it { should eq trim_spaces(expected) }
  end
end
