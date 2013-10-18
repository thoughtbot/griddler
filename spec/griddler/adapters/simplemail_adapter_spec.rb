require 'spec_helper'

describe Griddler::Adapters::SimplemailAdapter, '.normalize_params' do
  include Griddler::FixturesHelper

  it 'normalizes parameters' do
    Griddler::Adapters::SimplemailAdapter.normalize_params(default_params).should be_normalized_to({
      to: ['Alice <alice@example.com>'],
      from: 'bob@example.com',
      subject: 'Re: Sample POST request',
      text: 'hi'
    })
  end

  def default_params
    {
      to: 'Alice <alice@example.com>',
      from: 'bob@example.com',
      subject: 'Re: Sample POST request',
      text: 'hi'
    }
  end

end
