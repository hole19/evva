describe Evva::DataSource do
  subject(:dict) { Evva::DataSource.new(keys) }

  describe ".initialize" do
    let(:keys) { { "event" => { "kNo1" => "text" } } }
    it { expect { subject }.not_to raise_error }

    context "when created with invalid type parameters" do
      let(:keys) { "cenas" }
      it { expect { subject }.to raise_error /expected Hash/ }
    end

    context "when created with an invalid json schema" do
      let(:keys) { { "event" => "text" } }
      it { expect { subject }.to raise_error /event.+expected Hash/ }
    end

    context "when created with an invalid json schema" do
      let(:keys) { { "a-event" => { "kNo1" => { "wtvr" => "text" } } } }
      it { expect { subject }.to raise_error /a-event.+kNo1.+expected String/ }
    end

    context "when given empty translations" do
      let(:keys) { { "event" => { "kNo1" => nil } } }
      it { expect { subject }.not_to raise_error }
    end
  end
end
