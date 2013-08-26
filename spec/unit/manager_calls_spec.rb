require 'spec_helper'

describe 'Wrapi::Manager' do 

  describe '#fetch' do 

    context 'when foo is a symbol or string' do 
      it 'should invoke :foo upon a client'
    end


    context 'optional options' do 
      describe ':arguments' do 
        it 'expects arguments as an array'
        it 'does not dupe arguments'      
      end
    end
  end

  describe '#fetch_batch' do 
    context 'required options' do 
      describe ':while_condition' do 
        it 'must be present'
        it 'must be a lambda with arity of two'
        it 'must return a boolean'
      end

      describe ':response_callback' do 
        it 'if present, must be a lambda with arity of two'
        it "lambda's second argument is an array"
      end
    end

    context 'optional options' do 
      describe ':yield_to' do 
        context 'exists' do 
          it 'must be a block with arity of one'          
        end
      
        context 'does not exist' do 
          it 'returns an array of responses'
        end
      end
    end
  end

end