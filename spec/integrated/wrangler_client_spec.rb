require 'spec_helper'

class AbstractWrangler
  include Wrapi::Wrangler
end

class ConcreteWrangler
  include Wrapi::Wrangler

  def load_credentials(from_string)
    from_string.upcase
  end

  def parse_credentials(loaded_creds)
    loaded_creds.split(' ')
  end

  def initialize_client(str)
    str += '!'
  end

end

describe "Wrapi::Wrangler client setup" do 

  context 'the abstract definition' do 
    let(:wrangler){AbstractWrangler.new}
  
    describe '#load_credentials_and_initialize_clients' do 

      it 'takes in an argument and returns true' do 
        expect(wrangler.load_credentials_and_initialize_clients('whatev')).to be_true
      end

      it 'sets @credentials to an array' do 
        wrangler.load_credentials_and_initialize_clients('whatev')
        expect(wrangler.credentials).to be_an Array
      end

      it 'should have no clients' do 
        wrangler.load_credentials_and_initialize_clients(nil)
        expect(wrangler.has_clients?).to be_false
      end
    end
  end



  context 'actual defined Wrangler' do 
    it 'should have a queue of clients' do 
      wrangler = ConcreteWrangler.new
      wrangler.load_credentials_and_initialize_clients('hello world')

      expect(wrangler.clients.all?{|c| c.is_a?(ManagedClient)}).to be_true
      expect(wrangler.bare_clients).to include('HELLO!', 'WORLD!')
    end

    describe '.init_clients' do 
      it 'is a convenience class method that inits the Wrangler class and runs #load_credentials_and_initialize_clients' do 
        wrangler = ConcreteWrangler.init_clients('hi')
        expect(wrangler.bare_clients).to include('HI!')
      end
    end

  end


end