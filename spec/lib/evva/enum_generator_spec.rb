describe Evva::EnumGenerator do
  
  generator = Evva::EnumGenerator.new()
  enum = Evva::MixpanelEnum.new('CourseProfileSource', 'course_discovery,synced_courses')
  
  describe "#kotlin_enum" do
    it "returns the expected kotlin enum" do
      expected = 
      "enum class CourseProfileSource(val key: String) {\n"\
      "\tCOURSE_DISCOVERY('course_discovery'),\n"\
      "\tSYNCED_COURSES('synced_courses'),\n} \n"
      expect(generator.kotlin_enum(enum)).to eq expected
    end
  end

  describe "#generate_swift_enum" do
    it "return the expected swift enum" do
      expected = 
      "enum CourseProfileSource: String {\n"\
      "\tcase course_discovery = 'course_discovery'\n"\
      "\tcase synced_courses = 'synced_courses'\n} \n"
      expect(generator.generate_swift_enum(enum)).to eq expected
    end
  end
end