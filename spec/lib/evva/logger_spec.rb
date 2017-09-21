describe Evva::Logger do
  let(:summary) { Evva::Logger.summary }
  let(:info)    { summary[:info] }
  let(:warn)    { summary[:warn] }
  let(:error)   { summary[:error] }

  context 'when logging to info' do
    before { Evva::Logger.info 'msg' }

    it 'returns the expected totals' do
      expect(info).to  eq 1
      expect(warn).to  eq 0
      expect(error).to eq 0
    end
  end

  context 'when logging to warn' do
    before { Evva::Logger.warn 'msg' }

    it 'returns the expected totals' do
      expect(info).to  eq 0
      expect(warn).to  eq 1
      expect(error).to eq 0
    end
  end

  context 'when logging to error' do
    before { Evva::Logger.error 'msg' }

    it 'returns the expected totals' do
      expect(info).to  eq 0
      expect(warn).to  eq 0
      expect(error).to eq 1
    end
  end
end
