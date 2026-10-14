// Writes the fingerprint for one lens into lenses.json.
// Usage: STATICRYPT_PASSWORD=... node lens-fingerprint.js <lens>
// The key is derived exactly as StatiCrypt does (PBKDF2: 1,000 x SHA-1, then 14,000 and 585,000 x SHA-256,
// with the repository's salt); the fingerprint is HMAC-SHA-256 of "lens:<name>" with that key.
const fs = require("fs"), crypto = require("crypto");
const lens = process.argv[2], password = process.env.STATICRYPT_PASSWORD;
if (!lens || !/^[a-z0-9-]+$/.test(lens) || !password) { console.error("Usage: STATICRYPT_PASSWORD=... node lens-fingerprint.js <lens>"); process.exit(1); }
const salt = JSON.parse(fs.readFileSync(".staticrypt.json", "utf8")).salt;
const round = (p, n, h) => crypto.pbkdf2Sync(Buffer.from(p, "utf8"), Buffer.from(salt, "utf8"), n, 32, h).toString("hex");
const key = round(round(round(password, 1000, "sha1"), 14000, "sha256"), 585000, "sha256");
const fp = crypto.createHmac("sha256", Buffer.from(key, "hex")).update("lens:" + lens).digest("hex");
let cfg = { salt, lenses: {} };
try { cfg = JSON.parse(fs.readFileSync("lenses.json", "utf8")); } catch (e) {}
cfg.salt = salt; cfg.lenses = cfg.lenses || {}; cfg.lenses[lens] = fp;
for (const [other, f] of Object.entries(cfg.lenses)) if (other !== lens && f === fp) console.warn("Note: '" + other + "' uses the same password.");
fs.writeFileSync("lenses.json", JSON.stringify(cfg, null, 2) + "\n");
console.log("Fingerprint for '" + lens + "' (" + fp.slice(0, 8) + ", salt " + salt.slice(0, 8) + ") written to lenses.json");
// a check code for the password itself (never the password): compare it with password-check.html in the browser
const chars = [...password], nonAscii = chars.filter((c) => c.charCodeAt(0) > 127).length;
const code = crypto.createHash("sha256").update(Buffer.from(password, "utf8")).digest("hex").slice(0, 8);
console.log("Password received: " + chars.length + " characters (" + nonAscii + " non-ASCII" + (password !== password.trim() ? ", with leading/trailing spaces" : "") + "), check code " + code);
