// Open a built nimib page in headless Chromium, report console messages and page errors,
// optionally click elements and print text of elements afterwards.
// usage: node browser_check.mjs page.html [--click "css selector"]... [--text "css selector"]... [--network]
// By default external requests (CDN css/js: water.css, highlight.js, katex) are blocked so the check
// is deterministic offline; errors that only come from those missing scripts are ignored.
// Pass --network to load them.
// Needs the `playwright` npm package (and a Chromium it can launch).
import { createRequire } from "module";
import path from "path";
const require = createRequire(import.meta.url);
let playwright;
try { playwright = require("playwright"); }
catch { try { playwright = require(require.resolve("playwright", { paths: [process.cwd(), "/usr/lib/node_modules", "/usr/local/lib/node_modules"] })); }
catch { console.error("playwright not found: npm i -g playwright (or run from a folder where it is installed)"); process.exit(2); } }

const args = process.argv.slice(2);
if (!args.length) { console.error("usage: node browser_check.mjs page.html [--click sel]... [--text sel]..."); process.exit(2); }
const file = path.resolve(args[0]);
const clicks = [], texts = [];
let network = false;
for (let i = 1; i < args.length; i++) {
  if (args[i] === "--click") clicks.push(args[++i]);
  else if (args[i] === "--text") texts.push(args[++i]);
  else if (args[i] === "--network") network = true;
}
const browser = await playwright.chromium.launch();
const page = await browser.newPage();
const errors = [];
// errors caused by blocked CDN scripts, not by the document
const cdnErrors = [/hljs is not defined/, /renderMathInElement is not defined/, /katex is not defined/];
if (!network) await page.route(/^https?:/, route => route.abort());
page.on("console", m => {
  if (!network && m.type() === "error" && /Failed to load resource/.test(m.text())) return;
  console.log(`[console.${m.type()}] ${m.text()}`);
});
page.on("pageerror", e => {
  if (!network && cdnErrors.some(r => r.test(e.message))) return;
  errors.push(e.message); console.log(`[pageerror] ${e.message}`);
});
// external CDNs (water.css, highlight.js, katex) may be unreachable offline: don't wait for them
await page.goto("file://" + file, { waitUntil: "domcontentloaded" });
await page.waitForTimeout(500);
for (const sel of clicks) {
  try { await page.click(sel, { timeout: 2000 }); console.log(`[click] ${sel}`); }
  catch (e) { errors.push(`click ${sel}: ${e.message.split("\n")[0]}`); console.log(`[click-failed] ${sel}`); }
  await page.waitForTimeout(100);
}
for (const sel of texts) {
  const els = await page.$$(sel);
  if (!els.length) console.log(`[text] ${sel}: (no element)`);
  for (const el of els) console.log(`[text] ${sel}: ${(await el.innerText()).trim()}`);
}
await browser.close();
if (errors.length) { console.log(`FAIL: ${errors.length} error(s)`); process.exit(1); }
console.log("OK: no page errors");
