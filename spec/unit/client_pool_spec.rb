require 'spec_helper'

describe 'ClientPool' do 

  describe 'initialization' do 


    it 'accepts an array' do 
      expect(ClientPool.new([]).size).to eq 0      
    end

    before(:each) do 
      @pool = ClientPool.new([])
    end

    context "emptiness" do 
      it 'should be #empty?' do
        expect(@pool.empty?).to be_true
      end

      it 'should not have any clients' do 
        expect(@pool.find_client).to be_nil
      end
    end

    context "add clients" do 
      it 'should add one client' do 
        @pool.add_clients({name: 'Dan', id: 'hello world'})
        expect(@pool.size).to eq 1
      end

      it 'should add an array of clients' do 
        @pool.add_clients(4.times.map )
        expect(@pool.size).to eq 4
      end
    end



  end
end