const fs = require('fs');
const path = require('path');

const directories = [
  path.join(__dirname, 'src', 'routes'),
  path.join(__dirname, 'src', 'services')
];

function processFile(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  const initialContent = content;

  // Find all instances of queries.method(
  // and replace with await queries.method(
  // but avoid double awating if already there.
  
  // Regex to find queries.methodCall(...) capturing the rest of the line
  content = content.replace(/(?<!await\s+)queries\.(\w+)\(/g, 'await queries.$1(');

  if (content !== initialContent) {
      // Also ensure function wrapping it is async if not already
      // This might be tricky, we'll try to rely on typescript to tell us if we missed async.
      // But express handlers `(req, res) =>` can be easily converted to `async (req, res) =>`
      content = content.replace(/router\.(get|post|put|delete|patch)\('([^']+)',\s*(stellarPaywall\([^)]+\),\s*)?\(req: Request, res: Response\)\s*=>\s*\{/g, 
        (match, method, route, middleware) => {
          return `router.${method}('${route}', ${middleware || ''}async (req: Request, res: Response) => {`;
      });

      fs.writeFileSync(filePath, content, 'utf8');
      console.log(`Updated ${filePath}`);
  }
}

function traverse(dir) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    if (fs.statSync(fullPath).isDirectory()) {
      traverse(fullPath);
    } else if (fullPath.endsWith('.ts')) {
      processFile(fullPath);
    }
  }
}

for (const dir of directories) {
  traverse(dir);
}
console.log('Done converting queries.* to await queries.*');
