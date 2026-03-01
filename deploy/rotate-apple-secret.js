// Generates an Apple client secret JWT for Keycloak
// Used by the rotate-apple-secret GitHub Actions workflow

const crypto = require('crypto');

const privateKey = process.env.APPLE_P8_KEY;
const teamId = process.env.APPLE_TEAM_ID;
const serviceId = process.env.APPLE_SERVICE_ID;
const keyId = process.env.APPLE_KEY_ID;

if (!privateKey || !teamId || !serviceId || !keyId) {
  console.error('Missing required environment variables');
  process.exit(1);
}

const header = { alg: 'ES256', kid: keyId };
const now = Math.floor(Date.now() / 1000);
const claims = {
  iss: teamId,
  iat: now,
  exp: now + 86400 * 180, // 6 months
  aud: 'https://appleid.apple.com',
  sub: serviceId,
};

function base64url(obj) {
  return Buffer.from(JSON.stringify(obj))
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

const unsigned = base64url(header) + '.' + base64url(claims);
const key = crypto.createPrivateKey(privateKey);
const signature = crypto
  .sign('sha256', Buffer.from(unsigned), { key, dsaEncoding: 'ieee-p1363' })
  .toString('base64')
  .replace(/=/g, '')
  .replace(/\+/g, '-')
  .replace(/\//g, '_');

console.log(unsigned + '.' + signature);
