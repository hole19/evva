describe Evva::AndroidGenerator do
  generator = Evva::AndroidGenerator.new()

  describe "#kotlin_function" do
    context "event has no properties" do
      event = Evva::MixpanelEvent.new('trackNavFeedTap', "nav_feed_tap", [])
      it "returns the correct kotlin function" do
        expected = "\nfun trackNavFeedTap() {\n"\
        "\tmixpanelApi.trackEvent('nav_feed_tap')\n"\
        "}\n"
        expect(generator.kotlin_function(event)).to eq expected
      end
    end

    context "event has properties" do
      event = Evva::MixpanelEvent.new("trackCpPageView", 'cp_page_view', "course_id:Long,course_name:String")
      it "should parse the properties and return the correct event function" do
        expected = "\nfun trackCpPageView(course_id:Long,course_name:String) {\n"\
        "\tval properties = JSONObject().apply {\n"\
        "\t\tput('course_id', course_id)\n"\
        "\t\tput('course_name', course_name)\n\n"\
        "\t}\n"\
        "\tmixpanelApi.trackEvent('cp_page_view', properties)\n"\
        "}\n"
        expect(generator.kotlin_function(event)).to eq expected
      end
    end

    context "event has special properties" do 
      event = Evva::MixpanelEvent.new('trackCpPageView', 'cp_page_view', "course_id:Long,course_name:String,from_screen: CourseProfileSource")
      it "should parse the special properties and return the correct event function" do
        expected = "\nfun trackCpPageView(course_id:Long,course_name:String,from_screen: CourseProfileSource) {\n"\
        "\tval properties = JSONObject().apply {\n"\
        "\t\tput('course_id', course_id)\n"\
        "\t\tput('course_name', course_name)\n"\
        "\t\tput('from_screen', from_screen.key)\n\n"\
        "\t}\n"\
        "\tmixpanelApi.trackEvent('cp_page_view', properties)\n"\
        "}\n"
        expect(generator.kotlin_function(event)).to eq expected
      end
    end
  end


  describe "#kotlin_enum" do
    enum = Evva::MixpanelEnum.new('CourseProfileSource', 'course_discovery,synced_courses')

    it "returns the expected kotlin enum" do
      expected =
      "package com.hole19golf.hole19.analytics\n\n"\
      "enum class CourseProfileSource(val key: String) {\n"\
      "\tCOURSE_DISCOVERY('course_discovery'),\n"\
      "\tSYNCED_COURSES('synced_courses'),\n} \n"
      expect(generator.kotlin_enum(enum)).to eq expected
    end
  end

  describe "#is_special_property" do
    context "receives a regular property" do
       it do
        expect(generator.is_special_property("Long")).to eq false
      end
    end

    context "receives a special property" do
      it do
        expect(generator.is_special_property("course_profile_source")).to eq false
      end
    end
  end

  describe "#kotlin_const" do
    property = Evva::MixpanelProperty.new("RoundWithWear", "rounds_with_wear")
    it "should return the correctly formed constant" do
      expected = "\t\tconst val RoundWithWear = 'rounds_with_wear'\n"
      expect(generator.kotlin_const(property)).to eq expected
    end
  end

end
