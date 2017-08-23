describe Evva::EventGenerator do
    generator = Evva::EventGenerator.new()

    describe "#kotlin_function" do

        context "event has no properties" do
            event = Evva::MixpanelEvent.new("trackNavFeedTap", "nav_feed_tap", [])
            it "returns the correct kotlin function" do
                expected="\nfun trackNavFeedTap() {\n"\
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
            event = Evva::MixpanelEvent.new("trackCpPageView", 'cp_page_view', "course_id:Long,course_name:String,from_screen: CourseProfileSource")
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
end