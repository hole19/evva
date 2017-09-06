describe Evva::SwiftGenerator do
	generator = Evva::SwiftGenerator.new()

	describe "#is_special_property" do
		context "receives a regular property" do
			it do
				expect(generator.is_special_property('course_id:Long')).to eq false
			end
		end

		context "receives a special property" do
			it do
				expect(generator.is_special_property("course_profile_source")).to eq true
			end
		end
	end

	describe "#prepend_let" do
		properties = "course_id:Long,course_name:String,from_screen: CourseProfileSource?"
		it "should prepend a let to every argument on the function" do
			expected = "let course_id, let course_name, let from_screen"
			expect(generator.prepend_let(properties)).to eq expected
		end
	end

	describe "#swift_case" do 
		
		context "event has no properties" do
			event = Evva::MixpanelEvent.new('trackNavFeedTap', "nav_feed_tap", [])
			it "should create a case for an event to be tracked" do
				expected = "\t\tcase trackNavFeedTap\n"
				expect(generator.swift_case(event)).to eq expected
			end

		end

		context "event has properties" do 
			event = Evva::MixpanelEvent.new("trackCpPageView", 'cp_page_view', "course_id:Long,course_name:String")
			it "should create a case for an event to be tracked" do
				expected = "\t\tcase trackCpPageView(course_id:Long,course_name:String)\n"
				expect(generator.swift_case(event)).to eq expected
			end
		end
	end

	describe "#process_arguments" do
		properties = ("course_id:Long,course_name:String,from_screen: CourseProfileSource")
		it "should process the arguments looking for special properties" do
			expected = "\"course_id\":course_id, \"course_name\":course_name, \"from_screen\":from_screen.rawValue"
			expect(generator.process_arguments(properties)).to eq expected
		end
	end

  describe "#special_property_enum" do
    enum = Evva::MixpanelEnum.new('CourseProfileSource', 'course_discovery,synced_courses')

    it "returns the expected kotlin enum" do
      expected =
      "enum CourseProfileSource: String {\n"\
      "\tcase course_discovery = \"course_discovery\"\n"\
      "\tcase synced_courses = \"synced_courses\"\n} \n"
      expect(generator.special_property_enum(enum)).to eq expected
    end
  end

  describe "#swift_people_const" do
  	prop = Evva::MixpanelProperty.new('roundsWithWear', 'rounds_with_wear')
  	it "returns the expect people constant" do
  		expected = "\tcase roundsWithWear = \"rounds_with_wear\"\n"
  		expect(generator.swift_people_const(prop)).to eq expected
  	end
  end

end