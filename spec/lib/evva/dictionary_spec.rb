describe Evva::Dictionary do
  subject(:dict) { Evva::Dictionary.new(keys) }

  describe ".initialize" do
    let(:keys) { { "lang" => { "kNo1" => "text" } } }
    it { expect { subject }.not_to raise_error }

    context "when created with invalid type parameters" do
      let(:keys) { "cenas" }
      it { expect { subject }.to raise_error /expected Hash/ }
    end

    context "when created with an invalid json schema" do
      let(:keys) { { "lang" => "text" } }
      it { expect { subject }.to raise_error /lang.+expected Hash/ }
    end

    context "when created with an invalid json schema" do
      let(:keys) { { "a-lang" => { "kNo1" => { "wtvr" => "text" } } } }
      it { expect { subject }.to raise_error /a-lang.+kNo1.+expected String/ }
    end

    context "when given empty translations" do
      let(:keys) { { "lang" => { "kNo1" => nil } } }
      it { expect { subject }.not_to raise_error }
    end
  end
end
