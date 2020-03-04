RSpec.describe DomoRubySdk, vcr: true do

  let(:client_id) { ENV['V4SITE_TEST_DOMO_CLIENT_ID'] }
  let(:client_secret) { ENV['V4SITE_TEST_DOMO_CLIENT_SECRET'] }
  
  it "gets an access token" do
    domo = DomoRubySdk::Api.new(client_id, client_secret)
    domo.authenticate()
    expect(domo.access_token).to_not eq nil
  end

  it "gets datasets" do
    domo = DomoRubySdk::Api.new(client_id, client_secret)
    domo.authenticate()
    expect(domo.access_token).to_not eq nil
    datasets = domo.get_datasets()
  end

  it "creates and deletes dataset" do
    domo = DomoRubySdk::Api.new(client_id, client_secret)
    domo.authenticate()
    resp = domo.create_dataset(
      'Test Dataset',
      'For testing api only',
      [
        {
          type: 'STRING',
          name: 'Status'
        }, {
          type: 'STRING',
          name: 'Test Value'
        }
      ]
    )
    dataset_id = resp['id']
    expect(dataset_id).to_not eq nil

    resp = domo.get_dataset_metadata(dataset_id)
    expect(resp['name']).to eq 'Test Dataset'

    resp = domo.delete_dataset(dataset_id)
    expect { domo.get_dataset_metadata(dataset_id) }.to raise_error(RestClient::NotFound)
  end

  it "creates and deletes dataset stream and executions and uploads data" do
    domo = DomoRubySdk::Api.new(client_id, client_secret)
    domo.authenticate()
    resp = domo.create_dataset_stream(
      'Test Dataset',
      'For testing api only',
      [
        {
          type: 'STRING',
          name: 'Status'
        }, {
          type: 'STRING',
          name: 'Test Value'
        }
      ]
    )
    dataset_stream_id = resp['id']
    expect(dataset_stream_id).to_not eq nil
    dataset_id = resp['dataSet']['id']
    resp = domo.get_dataset_metadata(dataset_id)
    expect(resp['name']).to eq 'Test Dataset'

    stream_execution = domo.create_stream_execution(dataset_stream_id)
    stream_execution_id = stream_execution['id']
    expect(stream_execution_id).to_not eq nil
    csv_string = ["testing,foo","testing 1,foo squared"].join("\n")
    resp = domo.upload_stream_data_part(
      dataset_stream_id,
      stream_execution_id,
      1,
      csv_string
    )
    domo.finalize_stream_execution(dataset_stream_id, stream_execution_id)
    resp = domo.delete_dataset(dataset_id)
    expect { domo.get_dataset_metadata(dataset_id) }.to raise_error(RestClient::NotFound)
  end
end
