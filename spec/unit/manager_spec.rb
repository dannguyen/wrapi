require 'spec_helper'




describe "Wrapi::Manager" do

  describe '#fetch' do 


    context 'arguments' do 
      describe 'standard call with message and args' do 
        it 'should respond to message name and no args'
        it 'should respond to message name and several args'
      end

      describe 'custom proc' do 
        it 'should accept a proc with first arg as a client reference'
        it 'should yield control and pass along client reference'
      end
    end

    context 'block' do 
      context 'this is where looping is defined' do 

        it 'should yield control to a manager' do 

          pending %q{
notes:

# fetch 200 tweets from user @ev's timeline 
# =>  @tclient.user_timeline('ev', count: 200)
@manager.fetch(:user_timeline, count: 200)


# fetch 600 tweets from user @ev's timeline 
@manager.fetch(:user_timeline, count: 200) do |manager, response, state_of_fetch|

   TBD:::
  state_of_fetch.repeat ??
  response.on_success do |body|
    state = body.max_id
    @manager.fetch(:user_timeline, )
  end

end



          }
        end

      end
    end



  end




  describe '#find_client_from_pool' do 

    it 'should return one of its managed clients'


  end



  context 'pool management' do 

  end

  context 'batch calls' do 

    it 'should quit after lambda condition is reached'
    it 'should allow specification of one single client'

    context 'rate limit denials' do 
      it 'should punt to next client'
    end

  end

  # even singular calls should have rate limiting
  #
  # when a singular call fails, manager has number of retries
  context 'singular calls' do 

  end


end
