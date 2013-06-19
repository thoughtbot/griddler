describe Griddler::EmailParser do
  it "should extract the reply body for a blank message" do
    Griddler::EmailParser.extract_reply_body("").should == ""

    Griddler::EmailParser.extract_reply_body("------ Original Message ------\nhello").should == "hello"

    Griddler::EmailParser.extract_reply_body("hello\n------ Original Message ------\n foo bar baz").should == "hello"
  end
end