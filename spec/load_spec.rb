require 'spec_helper'

describe "loading data" do 
  it "loads" do 
    debugger
    DbSync.load_document('db_dump/articles.yml')
    Article.find_by_title("a_sample_article").content.should eql "a_sample_content"
  end

end
