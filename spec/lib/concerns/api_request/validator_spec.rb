module Test
  class Dummy
    include ControllerConcernTestHelpers
    include ApiGuardian::Concerns::ApiRequest::Validator
  end
end

describe ApiGuardian::Concerns::ApiRequest::Validator, type: :request do
  let(:dummy_class) { Test::Dummy.new }

  # Methods
  describe 'methods' do
    describe '#validate_api_request' do
      before(:each) do
        allow_any_instance_of(ActionDispatch::Request).to receive(:body).and_return(StringIO.new('body'))
        allow_any_instance_of(ActionDispatch::Request).to receive(:method).and_return(method)
        allow_any_instance_of(ActionDispatch::Request).to receive(:headers).and_return(headers)
        allow_any_instance_of(ActionController::Parameters).to receive(:fetch).with(:data).and_return(ActionController::Parameters.new)
        dummy_class.action_name = 'index'
      end

      let(:method) { nil }
      let(:headers) { {} }

      it 'validates the content type' do
        expect { dummy_class.validate_api_request }.to raise_error ApiGuardian::Errors::InvalidContentTypeError

        allow_any_instance_of(ActionDispatch::Request).to receive(:headers).and_return(get_headers)

        expect { dummy_class.validate_api_request }.not_to raise_error
      end

      context 'PUT request' do
        let(:method) { 'PUT' }
        let(:headers) { get_headers }

        it 'disallows PUT method for update action' do
          dummy_class.action_name = 'update'

          expect { dummy_class.validate_api_request }.to raise_error ApiGuardian::Errors::InvalidUpdateActionError, 'PUT'
        end
      end

      context 'POST request' do
        let(:method) { 'POST' }
        let(:headers) { get_headers }

        it 'validates request type' do
          # Invalid request body for type
          allow_any_instance_of(ActionController::Parameters).to receive(:fetch).with(:type, nil).and_return(nil)
          expect { dummy_class.validate_api_request }.to raise_error ApiGuardian::Errors::InvalidRequestBodyError, 'type'
          allow_any_instance_of(ActionController::Parameters).to receive(:fetch).with(:type, nil).and_return('users')
          expect { dummy_class.validate_api_request }.not_to raise_error

          # Invalid request resource type
          allow_any_instance_of(ActionController::Parameters).to receive(:fetch).with(:type, nil).and_return('test')
          expect { dummy_class.validate_api_request }.to raise_error ApiGuardian::Errors::InvalidRequestResourceTypeError, 'users'
          allow_any_instance_of(ActionController::Parameters).to receive(:fetch).with(:type, nil).and_return('users')
          expect { dummy_class.validate_api_request }.not_to raise_error
        end
      end

      context 'PATCH request' do
        let(:method) { 'PATCH' }
        let(:headers) { get_headers }

        it 'validates request id and type' do
          # We disable this setting because it bothers us about testing for specific errors.
          # In this case, though, it is intentional.
          RSpec::Expectations.configuration.warn_about_potential_false_positives = false

          # Invalid request body for ID
          allow_any_instance_of(ActionController::Parameters).to receive(:fetch).with(:id, nil).and_return(nil)
          expect { dummy_class.validate_api_request }.to raise_error ApiGuardian::Errors::InvalidRequestBodyError, 'id'
          allow_any_instance_of(ActionController::Parameters).to receive(:fetch).with(:id, nil).and_return('test')
          expect { dummy_class.validate_api_request }.not_to raise_error ApiGuardian::Errors::InvalidRequestBodyError, 'id'

          # Invalid request id matches param id
          allow_any_instance_of(ActionController::Parameters).to receive(:fetch).with(:id, nil).and_return('stuff')
          expect { dummy_class.validate_api_request }.to raise_error ApiGuardian::Errors::InvalidRequestResourceIdError, 'stuff'
          allow_any_instance_of(ActionController::Parameters).to receive(:fetch).with(:id, nil).and_return('test')
          expect { dummy_class.validate_api_request }.not_to raise_error ApiGuardian::Errors::InvalidRequestResourceIdError, 'stuff'

          # Invalid request body for type
          allow_any_instance_of(ActionController::Parameters).to receive(:fetch).with(:type, nil).and_return(nil)
          expect { dummy_class.validate_api_request }.to raise_error ApiGuardian::Errors::InvalidRequestBodyError, 'type'
          allow_any_instance_of(ActionController::Parameters).to receive(:fetch).with(:type, nil).and_return('users')
          expect { dummy_class.validate_api_request }.not_to raise_error

          # Invalid request resource type
          allow_any_instance_of(ActionController::Parameters).to receive(:fetch).with(:type, nil).and_return('test')
          expect { dummy_class.validate_api_request }.to raise_error ApiGuardian::Errors::InvalidRequestResourceTypeError, 'users'
          allow_any_instance_of(ActionController::Parameters).to receive(:fetch).with(:type, nil).and_return('users')
          expect { dummy_class.validate_api_request }.not_to raise_error

          # Turn the warning back on after this test
          RSpec::Expectations.configuration.warn_about_potential_false_positives = true
        end
      end
    end
  end
end