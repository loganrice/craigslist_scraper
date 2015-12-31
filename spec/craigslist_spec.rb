require 'craigslist_scraper/craigslist'

describe CraigsList do
  let!(:craigslist) { CraigsList.new }
  
  describe ".search" do
    before do
      allow(craigslist).to receive(:open).and_return(File.read(File.dirname(__FILE__) + '/mock_craigslist_data.html')) 
    end

    
    it "returns an array with all the items" do
      expect(craigslist.search.length).to eq(100)
      expect(craigslist.search[0].keys).to eq [:data_id, :description, :url, :price]
    end
	
    it "has the right keys " do
      expect(craigslist.search[0].keys).to eq [:data_id, :description, :url, :price]
    end
	
    it "addes '+' to white space in queries" do
      craigslist.search(city: "denver" , query: "iphone 5")
      expect(craigslist).to have_received(:open).with("http://denver.craigslist.org/search/sss?query=iphone+5")
    end
    
    it "adds title only filter to url" do
      craigslist.search(city: "denver" , query: "iphone 5" , title_only: true)
      expect(craigslist).to have_received(:open).with("http://denver.craigslist.org/search/sss?query=iphone+5&srchType=T")
    end
	  
    it "doesn't filter when title only is false" do
      craigslist.search(city: "denver" , query: "iphone 5" , title_only: false )
      expect(craigslist).to have_received(:open).with("http://denver.craigslist.org/search/sss?query=iphone+5")
    end
    
    it "exracts the price" do
      expect(craigslist.search[0][:price]).to  eq "70"
    end
    
    it "builds the correct reference url" do
      city = "shanghai"
      url = craigslist.search(city: city)[0][:url]
      expect(url).to eq "http://#{city}.craigslist.org/mob/3849318365.html"
    end

    it "returns [error: {}] if OpenURI::HTTPError is thrown" do
      exception_io = double('io')
      allow(exception_io).to receive_message_chain(:status, :[])
        .with(0).and_return('302')          
      allow(craigslist).to receive(:open).with(anything)
        .and_raise(OpenURI::HTTPError.new('',exception_io))
      
      error = craigslist.search(city: "somewhere")
      
      expect(error).to eq [{error: "error opening city: somewhere"} ]
    end
  end

  describe "dynamic method search_{cityname}_for" do
    it "calls search for a valid city" do
      allow(craigslist).to receive(:search)
      city = CraigsList::CITIES.first 
        
      craigslist.send("search_#{city}_for")

      expect(craigslist).to have_received(:search).with(city: city , query: nil)
    end
    
    it "doesn't call search for an invalid city" do
      expect { craigslist.search_yourmamaville_for }.to raise_error(NoMethodError)
    end

    it "passes a query" do
      allow(craigslist).to receive(:search)
      
      craigslist.search_dallas_for("cowboy hats")

      expect(craigslist).to have_received(:search).with(city: "dallas", query: "cowboy hats")
    end
  end

  
  describe "dynamic method search_titles_in_{cityname}_for" do
    
    it "calls search for a valid city" do
      city = CraigsList::CITIES.first
      allow(craigslist).to receive(:search)
        
      craigslist.send("search_titles_in_#{city}_for")

      expect(craigslist).to have_received(:search)
        .with(city: city , query: nil , title_only: true)
    end
    
    it "doesn't call search for an invalid city" do
      expect { craigslist.search_titles_in_yourmamaville_for }.to raise_error(NoMethodError)
    end
  end

  describe "Array#average_price" do

    it "returns the average price for a search with multiple items" do
      allow(craigslist).to receive(:search_denver_for)
        .and_return([{price: "3"} , {price: "5"} , {price: "7"}])
      
      average_price = craigslist.search_denver_for("uranium").average_price

      expect(average_price).to eq 5
    end

    it "returns 0 for search with no results" do
      allow(craigslist).to receive(:search_denver_for).and_return([])
      
      average_price = craigslist.search_denver_for("uranium").average_price 

      expect(average_price).to eq 0
    end

    it "returns average for a search with two items" do
      allow(craigslist).to receive(:search_denver_for)
        .and_return([{price: "8"} , {price: "12"} ])
      
      average_price = craigslist.search_denver_for("uranium").average_price

      expect(average_price).to eq 10
    end

    it "returns the price for a search with one item" do
      allow(craigslist).to receive(:search_denver_for)
        .and_return([{price: 1}])
      
      average_price = craigslist.search_denver_for("uranium").average_price 
      
      expect(average_price).to eq 1
    end

    it "discards nil prices" do
      allow(craigslist).to receive(:search_denver_for)
        .and_return([{price: 1} , {price: nil}])
      
      average_price = craigslist.search_denver_for("uranium").average_price
      
      expect(average_price).to eq 1      
    end

  end
  describe "Array#median_price" do

    it "returns the median price for a search with multiple items" do
      allow(craigslist).to receive(:search_denver_for)
        .and_return([{price: "1"} , {price: "1000"} , {price: "5"}])

      median_price = craigslist.search_denver_for("uranium").median_price 

      expect(median_price).to eq 5
    end

    it "returns 0 for search with no results" do
      allow(craigslist).to receive(:search_denver_for)
        .and_return([])
      
      median_price = craigslist.search_denver_for("uranium").median_price

      expect(median_price).to eq 0
    end
   
    it "returns median for a search with two items" do
      allow(craigslist).to receive(:search_denver_for)
        .and_return([{price: "8"} , {price: "12"} ])
   
      median_price = craigslist.search_denver_for("uranium").median_price
      
      expect(median_price).to eq 10
    end

    it "returns the price for a search with one item" do
      allow(craigslist).to receive(:search_denver_for)
        .and_return([{price: 1}])
   
      median_price = craigslist.search_denver_for("uranium").median_price
      
      expect(median_price).to eq 1
    end

    it "returns the average of the two middle numbers for an even array" do
      allow(craigslist).to receive(:search_denver_for)
        .and_return([{price: "1"} , {price: "5"} , {price: "15"} , {price: "10000"}])
      
      median_price = craigslist.search_denver_for("uranium").median_price
     
      expect(median_price).to eq 10
    end
    
    it "discards nil prices" do
      allow(craigslist).to receive(:search_denver_for)
        .and_return([{price: 1} , {price: nil}])
   
      median_price = craigslist.search_denver_for("uranium").median_price
      
      expect(median_price).to eq 1
    end
  end

  describe ".search_all_cities_for" do
    
    it "returns [] for cities with no search results" do
      stub_const("Cities::CITIES",["denver","boulder"])
      allow(craigslist).to receive(:search)
        .with(city: "denver" , query:"something cool" ).and_return([])
      allow(craigslist).to receive(:search)
        .with(city: "boulder", query:"something cool" ).and_return([])
      
      expect(craigslist.search_all_cities_for("something cool")).to eq []
    end

    it "returns concatenated items for cities with  search results" do
      stub_const("Cities::CITIES",["denver","boulder"])
      allow(craigslist).to receive(:search)
        .with(city: "denver" , query:"something cool" )
        .and_return([{in_denver: "something in denver"}])
      allow(craigslist).to receive(:search)
        .with(city: "boulder", query:"something cool" )
        .and_return([{in_boulder: "something in boulder"}])
      
      query = craigslist.search_all_cities_for("something cool")
     
      expect(query).to eq [{in_denver: "something in denver"}, {in_boulder: "something in boulder"}]
    end

  end
end

