import * as hcSeedBundle from "@holochain/hc-seed-bundle";
import { program } from "commander";
import { input } from "@inquirer/prompts";
import * as fs from "node:fs";
import _sodium from 'libsodium-wrappers';

program
  .command("generate")
  .description("Generate a new root seed bundle")
  .requiredOption("--out <file>", "Output file")
  .action(async (options) => {
    const root = hcSeedBundle.UnlockedSeedBundle.newRandom({
      bundleType: "root",
    });

    const passphrase = await input({
      message: "Enter a passphrase: ",
      type: "password",
    });
    const pw = new TextEncoder().encode(passphrase);

    const encodedBytes = root.lock([
      new hcSeedBundle.SeedCipherPwHash(
        hcSeedBundle.parseSecret(pw),
        "moderate",
      ),
    ]);

    root.zero();

    saveSeedBundle(encodedBytes, options);
  });

program.command('derive')
    .requiredOption('--root <file>', 'The root seed bundle')
    .requiredOption('--out <file>', 'Output file')
    .action(async (options) => {
      const root = await loadSeedBundle({ in: options.root });

      const derived = root.derive(68, {
        bundleType: "deviceRoot"
      });

      const passphrase = await input({
        message: 'Enter a passphrase: ',
        type: 'password'
      });
      const pw = new TextEncoder().encode(passphrase);

      const encodedBytes = derived.lock([
          new hcSeedBundle.SeedCipherPwHash(hcSeedBundle.parseSecret(pw), 'moderate')
      ]);

      derived.zero();

      saveSeedBundle(encodedBytes, { out: options.out });
    });

program.command('show')
    .requiredOption('--in <file>', 'Input file')
    .action(async (options) => {
      const unlocked = await loadSeedBundle(options);

      // This will print the public information of the unlocked seed with the private
      // portion zeroed out.
      unlocked.zero();
      console.log(unlocked);
    });

(async () => {
  await hcSeedBundle.seedBundleReady;
  await _sodium.ready;
  program.parse();
})();

const loadSeedBundle = async (options) => {
  fs.openSync(options.in, 'r');
  const encoded = fs.readFileSync(options.in, 'utf-8');

  const encodedBytes = fromBase64(encoded);

  const cipherList = hcSeedBundle.UnlockedSeedBundle.fromLocked(encodedBytes);

  if (!(cipherList[0] instanceof hcSeedBundle.LockedSeedCipherPwHash)) {
    throw new Error('This seed bundle isn\'t encrypted with a passphrase');
  }

  const passphrase = await input({
    message: 'Enter the passphrase to unlock this bundle: ',
    type: 'password'
  });

  const pw = new TextEncoder().encode(passphrase);

  return cipherList[0].unlock(hcSeedBundle.parseSecret(pw));
}

const saveSeedBundle = (encodedBytes, options) => {
  const encoded = toBase64(encodedBytes);
  const f = fs.openSync(options.out, "w");
  fs.writeSync(f, encoded, 0, "utf-8");
}

const toBase64 = (encodedBytes) => {
  return _sodium.to_base64(encodedBytes, _sodium.base64_variants.URLSAFE_NO_PADDING);
};

const fromBase64 = (encoded) => {
  return _sodium.from_base64(encoded, _sodium.base64_variants.URLSAFE_NO_PADDING);
}
