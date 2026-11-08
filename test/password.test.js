const test = require('node:test');
const assert = require('node:assert');

const password = require('../js/tools/password');

const hash = 'a'.repeat(128);

test('make is deterministic', () => {
    assert.equal(password.make(hash, 'abc'), password.make(hash, 'abc'));
});

test('make returns one character per pattern character', () => {
    assert.equal(password.make(hash, 'abc').length, 3);
    assert.equal(password.make(hash, 'abcdefgh').length, 8);
});

test('make gives different passwords for different patterns', () => {
    assert.notEqual(password.make(hash, 'abc'), password.make(hash, 'abd'));
});

test('make gives different passwords for different hashes', () => {
    assert.notEqual(password.make(hash, 'abc'), password.make('b'.repeat(128), 'abc'));
});

test('make picks every character from the charset of its pattern character', () => {
    const letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVXYZ';
    const pw = password.make(hash, 'aA0-.');
    assert.match(pw[0], /^[a-zA-Z]$/);
    assert.match(pw[1], /^[a-zA-Z]$/);
    assert.match(pw[2], /^[0-9]$/);
    assert.equal(pw[3], '-');
    assert.equal(pw[4], '.');
    assert.ok(letters.includes(pw[0]));
});

test('isValidPattern accepts known characters only', () => {
    assert.equal(password.isValidPattern('abcABC012-.'), true);
    assert.equal(password.isValidPattern('abc def'), false);
    assert.equal(password.isValidPattern('abc€'), false);
});
