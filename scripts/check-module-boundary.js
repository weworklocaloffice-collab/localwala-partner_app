const fs = require('fs');
const path = require('path');

const storesDir = path.join(__dirname, '..', 'lib', 'app', 'modules', 'stores');
const forbidden = ['package:partner/app/core'];

let violations = 0;
function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full);
    } else if (entry.name.endsWith('.dart')) {
      const content = fs.readFileSync(full, 'utf8');
      // The repository is the boundary layer: it is allowed to import core
      // services. Shell views need UserSessionModel for the role gate. Screens
      // and widgets must not import core directly.
      if (full.includes('stores_partner_repository.dart')) return;
      if (full.includes('_shell_view.dart')) return;
      for (const line of content.split('\n')) {
        for (const f of forbidden) {
          if (line.includes(f)) {
            console.log('VIOLATION:', full.replace(process.cwd() + path.sep, ''), '->', line.trim());
            violations++;
          }
        }
      }
    }
  }
}

walk(storesDir);
console.log(violations === 0 ? 'PASS: no module boundary violations' : `FAIL: ${violations} violation(s)`);
process.exit(violations === 0 ? 0 : 1);
