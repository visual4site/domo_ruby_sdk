RSpec.describe DomoRubySdk, vcr: true do
  let(:client_id) { ENV['V4SITE_TEST_DOMO_CLIENT_ID'] }
  let(:client_secret) { ENV['V4SITE_TEST_DOMO_CLIENT_SECRET'] }
  let(:domo) { DomoRubySdk::Api.new(client_id, client_secret) }
  
  describe ".authenticate" do
    context "no client id or client secret" do
      it "raises an exception" do
        bad_domo = DomoRubySdk::Api.new('','')
        expect { bad_domo.authenticate() }.to raise_error(DomoRubySdk::SdkException)
      end
    end
    context "given a client id and client secret" do
      it "gets an access token" do
        domo.authenticate()
        expect(domo.access_token).to_not eq nil
      end
    end
  end

  describe "dataset CRUD operations" do
    it "creates a dataset" do
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
      $dataset_id = resp['id']
      expect(resp['name']).to eq 'Test Dataset'
    end
    it "uploads data" do
      csv_string = ["testing,foo","testing 1,foo squared"].join("\n")
      resp = domo.append_dataset($dataset_id, csv_string)
      expect(resp.code).to eq 204
    end
    it "gets dataset metadata" do
      sleep(5)
      resp = domo.get_dataset_metadata($dataset_id)
      expect(resp['rows']).to eq 2
    end
    it "updates dataset" do
      csv_string = ["new,column,test"].join("\n")
      resp = domo.update_dataset($dataset_id,
        [
          {
            type: 'STRING',
            name: 'Status'
          }, {
            type: 'STRING',
            name: 'Test Value'
          }, {
            type: 'STRING',
            name: 'New Column'
          }
        ]  
      )
      expect(resp['name']).to eq 'Test Dataset'
      resp = domo.append_dataset($dataset_id,csv_string)
      expect(resp.code).to eq 204
      sleep(5)
      resp = domo.get_dataset_metadata($dataset_id)
      expect(resp['columns']).to eq 3
      expect(resp['rows']).to eq 3
    end
    it "queries dataset and replaces data" do
      csv_string = domo.query_dataset($dataset_id)
      resp = domo.replace_dataset($dataset_id,csv_string)
      expect(resp.code).to eq 204
      sleep(5)
      resp = domo.get_dataset_metadata($dataset_id)
      expect(resp['columns']).to eq 3
      expect(resp['rows']).to eq 3
    end
    it "deletes dataset" do
      resp = domo.delete_dataset($dataset_id)
      expect(resp.code).to eq 204
    end
  end
    
end