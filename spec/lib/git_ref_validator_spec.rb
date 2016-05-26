require 'spec_helper'

describe Gitlab::GitRefValidator, lib: true do
  it { expect(described_class.validate('feature/new')).to be_truthy }
  it { expect(described_class.validate('implement_@all')).to be_truthy }
  it { expect(described_class.validate('my_new_feature')).to be_truthy }
  it { expect(described_class.validate('#1')).to be_truthy }
  it { expect(described_class.validate('feature/~new/')).to be_falsey }
  it { expect(described_class.validate('feature/^new/')).to be_falsey }
  it { expect(described_class.validate('feature/:new/')).to be_falsey }
  it { expect(described_class.validate('feature/?new/')).to be_falsey }
  it { expect(described_class.validate('feature/*new/')).to be_falsey }
  it { expect(described_class.validate('feature/[new/')).to be_falsey }
  it { expect(described_class.validate('feature/new/')).to be_falsey }
  it { expect(described_class.validate('feature/new.')).to be_falsey }
  it { expect(described_class.validate('feature\@{')).to be_falsey }
  it { expect(described_class.validate('feature\new')).to be_falsey }
  it { expect(described_class.validate('feature//new')).to be_falsey }
  it { expect(described_class.validate('feature new')).to be_falsey }
end
