require('../spec_helper')

const fs = require(`${lib}/fs`)
const makeUserPackageFile = require('../../scripts/build')
const snapshot = require('snap-shot-it')
const la = require('lazy-ass')
const is = require('check-more-types')
const R = require('ramda')

const hasVersion = (json) =>
  la(is.semver(json.version), 'cannot find version', json)

const hasAuthor = (json) =>
  la(json.author === 'Brian Mann', 'wrong author name', json)

const changeVersion = R.assoc('version', 'x.y.z')

describe('package.json build', () => {
  beforeEach(function () {
    // stub package.json in CLI
    // with a few test props
    // the rest should come from root package.json file
    this.sandbox.stub(fs, 'readJsonAsync').resolves({
      name: 'test',
      engines: 'test engines',
    })
    this.sandbox.stub(fs, 'outputJsonAsync').resolves()
  })

  it('author name and version', () => {
    return makeUserPackageFile()
    .tap(hasAuthor)
    .tap(hasVersion)
  })

  it('outputs expected properties', () => {
    return makeUserPackageFile()
    .then(changeVersion)
    .then(snapshot)
  })
})
