const test = require('node:test');
const assert = require('node:assert');

const urltools = require('../js/tools/urltools');

test('extractDomain strips www and keeps the registrable domain', () => {
    assert.equal(urltools.extractDomain('https://www.example.com/foo/bar'), 'example.com');
    assert.equal(urltools.extractDomain('example.com'), 'example.com');
});

test('extractDomain only knows single part top level domains', () => {
    // 'co.uk' is not in the list of known top level domains, so the domain
    // is cut after the last known one.
    assert.equal(urltools.extractDomain('https://sub.example.co.uk/x'), 'co.uk');
});

test('extractDomain returns undefined for unknown top level domains', () => {
    assert.equal(urltools.extractDomain('https://foo.notatld'), undefined);
});

test('extractSite returns the host of a link', () => {
    assert.equal(urltools.extractSite('go to https://www.example.com/x now'), 'example.com');
});

test('containsLink finds links in text', () => {
    assert.equal(urltools.containsLink('visit https://example.com today'), true);
    assert.equal(urltools.containsLink('nothing here'), false);
});

test('shortenLink cuts long links', () => {
    // links longer than the given length are shortened to their host name
    assert.equal(urltools.shortenLink('https://www.example.com/', 10), 'example');
    assert.equal(urltools.shortenLink('https://www.example.com/some/path', 20), 'example/some/path');
});
