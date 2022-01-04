describe Evva::AndroidGenerator do
  let(:generator) { described_class.new("com.hole19golf.hole19.analytics") }

  describe '#events' do
    subject { generator.events(events, "AnalyticsEvent", "AnalyticsEvents", "AnalyticsDestinations") }

    let(:events) { [
      Evva::AnalyticsEvent.new('cp_page_view', {}, []),
      Evva::AnalyticsEvent.new('cp_page_view_2', {}, ["firebase"]),
      Evva::AnalyticsEvent.new('cp_page_view_a', { course_id: 'Long', course_name: 'String' }, ["firebase", "custom destination"]),
      Evva::AnalyticsEvent.new('cp_page_view_b', { course_id: 'Long', course_name: 'String', from_screen: 'CourseProfileSource' }, ["firebase"]),
      Evva::AnalyticsEvent.new('cp_page_view_c', { course_id: 'Long', course_name: 'String', from_screen: 'CourseProfileSource?' }, []),
      Evva::AnalyticsEvent.new('cp_page_view_d', { course_id: 'Long?', course_name: 'String' }, []),
    ] }

    let(:expected) {
<<-Kotlin
package com.hole19golf.hole19.analytics

/**
 * This file was automatically generated by evva: https://github.com/hole19/evva
 */

sealed class AnalyticsEvent(
    event: AnalyticsEvents,
    val properties: Map<String, Any?>? = null,
    val destinations: Array<AnalyticsDestinations> = emptyArray()
) {
    val name = event.key

    object CpPageView : AnalyticsEvent(
        event = AnalyticsEvents.CP_PAGE_VIEW,
    )

    object CpPageView2 : AnalyticsEvent(
        event = AnalyticsEvents.CP_PAGE_VIEW_2,
        destinations = arrayOf(
            AnalyticsDestinations.FIREBASE
        )
    )

    data class CpPageViewA(
        val courseId: Long, val courseName: String
    ) : AnalyticsEvent(
        event = AnalyticsEvents.CP_PAGE_VIEW_A,
        properties = mapOf(
            "course_id" to courseId,
            "course_name" to courseName
        ),
        destinations = arrayOf(
            AnalyticsDestinations.FIREBASE,
            AnalyticsDestinations.CUSTOM_DESTINATION
        )
    )

    data class CpPageViewB(
        val courseId: Long, val courseName: String, val fromScreen: CourseProfileSource
    ) : AnalyticsEvent(
        event = AnalyticsEvents.CP_PAGE_VIEW_B,
        properties = mapOf(
            "course_id" to courseId,
            "course_name" to courseName,
            "from_screen" to fromScreen.key
        ),
        destinations = arrayOf(
            AnalyticsDestinations.FIREBASE
        )
    )

    data class CpPageViewC(
        val courseId: Long, val courseName: String, val fromScreen: CourseProfileSource?
    ) : AnalyticsEvent(
        event = AnalyticsEvents.CP_PAGE_VIEW_C,
        properties = mapOf(
            "course_id" to courseId,
            "course_name" to courseName,
            "from_screen" to fromScreen?.key
        ),
    )

    data class CpPageViewD(
        val courseId: Long?, val courseName: String
    ) : AnalyticsEvent(
        event = AnalyticsEvents.CP_PAGE_VIEW_D,
        properties = mapOf(
            "course_id" to courseId,
            "course_name" to courseName
        ),
    )
}
Kotlin
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
<<-Kotlin
package com.hole19golf.hole19.analytics

/**
 * This file was automatically generated by evva: https://github.com/hole19/evva
 */

enum class CourseProfileSource(val key: String) {
    COURSE_DISCOVERY("course_discovery"),
    SYNCED_COURSES("synced_courses");
}

enum class PremiumFrom(val key: String) {
    COURSE_PROFILE("Course Profile"),
    ROUND_SETUP("Round Setup");
}
Kotlin
     }
    it { should eq expected }
  end

  describe '#event_enum' do
    subject { generator.event_enum(event_bundle, 'AnalyticsEvents') }
    let(:event_bundle) { [
      Evva::AnalyticsEvent.new('nav_feed_tap', {}, []),
      Evva::AnalyticsEvent.new('nav_performance_tap', {}, []),
      ] }
    let(:expected) {
<<-Kotlin
package com.hole19golf.hole19.analytics

/**
 * This file was automatically generated by evva: https://github.com/hole19/evva
 */

enum class AnalyticsEvents(val key: String) {
    NAV_FEED_TAP("nav_feed_tap"),
    NAV_PERFORMANCE_TAP("nav_performance_tap");
}
Kotlin
     }
    it { should eq expected }
  end

  describe '#people_properties' do
    subject { generator.people_properties(people_bundle, 'AnalyticsProperty', 'AnalyticsProperties', 'AnalyticsDestinations') }
    let(:people_bundle) { [
      Evva::AnalyticsProperty.new('rounds_with_wear', 'String', []),
      Evva::AnalyticsProperty.new('wear_platform', 'WearableAppPlatform', ["firebase", "custom destination"]),
    ] }
    let(:expected) {
<<-Kotlin
package com.hole19golf.hole19.analytics

/**
 * This file was automatically generated by evva: https://github.com/hole19/evva
 */

sealed class AnalyticsProperty(
    property: AnalyticsProperties,
    val innerValue: Any,
    val destinations: Array<AnalyticsDestinations> = emptyArray()
) {
    val name = property.key

    data class RoundsWithWear(
        val value: String
    ) : AnalyticsProperty(
        property = AnalyticsProperties.ROUNDS_WITH_WEAR,
        innerValue = value,
    )

    data class WearPlatform(
        val value: WearableAppPlatform
    ) : AnalyticsProperty(
        property = AnalyticsProperties.WEAR_PLATFORM,
        innerValue = value.key,
        destinations = arrayOf(
            AnalyticsDestinations.FIREBASE,
            AnalyticsDestinations.CUSTOM_DESTINATION
        )
    )
}
Kotlin
    }

    it { should eq expected }
  end

  describe '#people_properties_enum' do
    subject { generator.people_properties_enum(people_bundle, 'AnalyticsProperties') }
    let(:people_bundle) { [
      Evva::AnalyticsProperty.new('rounds_with_wear', 'String', ["firebase"]),
      Evva::AnalyticsProperty.new('wear_platform', 'WearableAppPlatform', ["firebase", "custom destination"]),
    ] }
    let(:expected) {
<<-Kotlin
package com.hole19golf.hole19.analytics

/**
 * This file was automatically generated by evva: https://github.com/hole19/evva
 */

enum class AnalyticsProperties(val key: String) {
    ROUNDS_WITH_WEAR("rounds_with_wear"),
    WEAR_PLATFORM("wear_platform");
}
Kotlin
    }
    it { should eq expected }
  end

  describe '#destinations' do
    subject { generator.destinations(destinations_bundle, 'AnalyticsDestinations') }
    let(:destinations_bundle) { [
      'firebase',
      'whatever you want really'
    ] }
    let(:expected) {
<<-Kotlin
package com.hole19golf.hole19.analytics

/**
 * This file was automatically generated by evva: https://github.com/hole19/evva
 */

enum class AnalyticsDestinations {
    FIREBASE,
    WHATEVER_YOU_WANT_REALLY;
}
Kotlin
    }
    it { should eq expected }
  end
end
