const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const cryptools = require('../js/tools/cryptools');

// Ciphertext of 'hello turtle' with master key 'masterkey', produced by the
// legacy crypto.createCipher() (openssl EVP_BytesToKey, md5, no salt) that
// older versions of this app used to encrypt the stash file.
const legacyCiphertext = 'fad7f97f23170c185f7aa8d7334b2384';

test('genHash is the hex sha512 of the value', () => {
    assert.equal(
        cryptools.genHash('masterkey'),
        'd5f92dcae90ec87247840df8a76a195aa1cd0f7fe996b1d79eb6f9da2294338a55' +
        '6b46cfd64e0fe3a00b71952e17a72880b01540485924150fbb5448098e6853'
    );
});

test('encrypt and decrypt round trip', () => {
    const enc = cryptools.encrypt('hello turtle', 'masterkey');
    assert.notEqual(enc, 'hello turtle');
    assert.equal(cryptools.decrypt(enc, 'masterkey'), 'hello turtle');
});

test('encrypt is deterministic for the same key', () => {
    assert.equal(
        cryptools.encrypt('hello turtle', 'masterkey'),
        cryptools.encrypt('hello turtle', 'masterkey')
    );
});

test('decrypt reads files written by the legacy createCipher', () => {
    assert.equal(cryptools.decrypt(legacyCiphertext, 'masterkey'), 'hello turtle');
});

test('decrypt fails with a wrong key', () => {
    assert.throws(() => cryptools.decrypt(legacyCiphertext, 'wrongkey'));
});

test('encryptFile and decryptFile round trip', () => {
    const file = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'pt-')), 'stash');
    cryptools.encryptFile(file, Buffer.from('{"pattern":"abc"}', 'utf8'), 'masterkey');
    assert.equal(fs.readFileSync(file, 'utf8').length > 0, true);

    const result = cryptools.decryptFile(file, 'masterkey', (err, json) => {
        assert.equal(err, null);
        assert.equal(json, '{"pattern":"abc"}');
    });
    assert.equal(result, undefined);
});

test('decryptFile reports an error for a wrong key', () => {
    const file = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'pt-')), 'stash');
    cryptools.encryptFile(file, Buffer.from('secret', 'utf8'), 'masterkey');

    let error = null;
    cryptools.decryptFile(file, 'wrongkey', (err) => {
        error = err;
    });
    assert.notEqual(error, null);
});
