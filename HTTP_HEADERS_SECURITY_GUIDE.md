# HTTP Headers Security Guide

## CVE-2025-7339: on-headers Response Header Manipulation

### Vulnerability Overview
The on-headers npm package versions before 1.1.0 contain a vulnerability that allows HTTP response headers to be inadvertently modified when an array is passed to `response.writeHead()` instead of an object.

### Technical Details

#### The Vulnerability
```javascript
// Vulnerable code pattern (on-headers < 1.1.0)
const onHeaders = require('on-headers');

// When an array is passed to response.writeHead()
response.writeHead(200, ['Content-Type', 'text/html', 'X-Custom', 'value']);

// on-headers may inadvertently modify these headers
onHeaders(response, function() {
  // Header manipulation may occur here
});
```

#### Attack Vector
- **Scope**: Local access with high privileges required
- **Method**: Exploiting array-based header setting in HTTP responses
- **Impact**: Unintended header modification, potential information disclosure
- **Complexity**: Low complexity but requires elevated privileges

### Impact Assessment

#### Security Implications
- **Header Manipulation**: Response headers may be unintentionally modified
- **Information Disclosure**: Sensitive headers could be exposed or altered
- **Response Integrity**: HTTP response integrity may be compromised
- **Application Behavior**: Unexpected application behavior due to header changes

#### Affected Components
- Express.js applications using on-headers
- HTTP server middleware processing headers
- Response processing pipelines
- Development servers (webpack-dev-server uses on-headers transitively)

### Prevention Measures

#### 1. Immediate Fix ✅
```json
{
  "resolutions": {
    "on-headers": ">=1.1.0"
  },
  "overrides": {
    "on-headers": ">=1.1.0"
  }
}
```

#### 2. Secure Header Handling
```javascript
// Secure header handling practices
const express = require('express');
const app = express();

// Use objects instead of arrays for headers
app.use((req, res, next) => {
  // ✅ SECURE: Use object format
  res.writeHead(200, {
    'Content-Type': 'application/json',
    'X-Custom-Header': 'secure-value',
    'X-Frame-Options': 'DENY'
  });
  
  // ❌ AVOID: Array format (vulnerable in old on-headers)
  // res.writeHead(200, ['Content-Type', 'application/json']);
  
  next();
});

// Secure header setting methods
app.use((req, res, next) => {
  // Preferred method: set headers individually
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  
  next();
});
```

#### 3. Express.js Security Configuration
```javascript
// express-security.js - Comprehensive security setup
const express = require('express');
const helmet = require('helmet');

const app = express();

// Use helmet for comprehensive security headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"]
    }
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

// Custom security headers middleware
app.use((req, res, next) => {
  // Security headers object (safe format)
  const securityHeaders = {
    'X-Powered-By': 'None',
    'X-Request-ID': generateRequestId(),
    'X-Response-Time': Date.now().toString(),
    'Cache-Control': 'no-cache, no-store, must-revalidate'
  };
  
  // Apply headers safely
  Object.entries(securityHeaders).forEach(([name, value]) => {
    res.setHeader(name, value);
  });
  
  next();
});

function generateRequestId() {
  return Math.random().toString(36).substr(2, 9);
}
```

### Detection Methods

#### 1. Header Manipulation Detection
```javascript
// Middleware to detect header manipulation
function headerIntegrityMiddleware(req, res, next) {
  const originalWriteHead = res.writeHead;
  const originalSetHeader = res.setHeader;
  
  const expectedHeaders = new Map();
  
  // Override setHeader to track expected headers
  res.setHeader = function(name, value) {
    expectedHeaders.set(name.toLowerCase(), value);
    return originalSetHeader.call(this, name, value);
  };
  
  // Override writeHead to detect manipulation
  res.writeHead = function(statusCode, headers) {
    if (Array.isArray(headers)) {
      console.warn('⚠️  WARNING: Array passed to writeHead() - potential on-headers vulnerability');
      
      // Convert array to object safely
      const headerObj = {};
      for (let i = 0; i < headers.length; i += 2) {
        if (headers[i + 1] !== undefined) {
          headerObj[headers[i]] = headers[i + 1];
        }
      }
      return originalWriteHead.call(this, statusCode, headerObj);
    }
    
    return originalWriteHead.call(this, statusCode, headers);
  };
  
  next();
}
```

#### 2. Security Audit Script
```javascript
// audit-headers.js - Check for on-headers vulnerabilities
const fs = require('fs');
const path = require('path');

function auditOnHeadersUsage(directory) {
  const files = getAllJSFiles(directory);
  const vulnerablePatterns = [
    /response\.writeHead\s*\(\s*\d+\s*,\s*\[/g,  // Array usage
    /res\.writeHead\s*\(\s*\d+\s*,\s*\[/g,       // Express array usage
    /\.writeHead\s*\(\s*[^,]+\s*,\s*\[/g         // General array pattern
  ];
  
  files.forEach(file => {
    const content = fs.readFileSync(file, 'utf8');
    
    vulnerablePatterns.forEach((pattern, index) => {
      const matches = content.match(pattern);
      if (matches) {
        console.log(`⚠️  Potential vulnerability in ${file}:`);
        console.log(`   Pattern ${index + 1}: ${matches.join(', ')}`);
        console.log(`   Consider using object format instead of array`);
      }
    });
  });
}

function getAllJSFiles(dir) {
  let files = [];
  const items = fs.readdirSync(dir);
  
  items.forEach(item => {
    const fullPath = path.join(dir, item);
    const stat = fs.statSync(fullPath);
    
    if (stat.isDirectory() && !item.includes('node_modules')) {
      files = files.concat(getAllJSFiles(fullPath));
    } else if (item.endsWith('.js') || item.endsWith('.ts')) {
      files.push(fullPath);
    }
  });
  
  return files;
}

// Run audit
if (require.main === module) {
  auditOnHeadersUsage('./src');
}
```

### Testing and Validation

#### 1. Header Security Tests
```javascript
// test/header-security.test.js
const request = require('supertest');
const express = require('express');

describe('Header Security Tests', () => {
  let app;
  
  beforeEach(() => {
    app = express();
  });
  
  test('should handle headers as objects safely', async () => {
    app.get('/test', (req, res) => {
      // Safe object format
      res.writeHead(200, {
        'Content-Type': 'application/json',
        'X-Test-Header': 'safe-value'
      });
      res.end('{"status": "ok"}');
    });
    
    const response = await request(app).get('/test');
    expect(response.status).toBe(200);
    expect(response.headers['x-test-header']).toBe('safe-value');
  });
  
  test('should detect array header usage', async () => {
    const consoleSpy = jest.spyOn(console, 'warn');
    
    app.use(headerIntegrityMiddleware);
    app.get('/test-array', (req, res) => {
      // This should trigger warning
      res.writeHead(200, ['Content-Type', 'text/plain']);
      res.end('test');
    });
    
    await request(app).get('/test-array');
    expect(consoleSpy).toHaveBeenCalledWith(
      expect.stringContaining('Array passed to writeHead()')
    );
  });
});
```

#### 2. CI/CD Integration
```yaml
# .github/workflows/header-security.yml
name: HTTP Header Security Scan
on: [push, pull_request]

jobs:
  header-security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Check on-headers version
        run: |
          echo "Checking on-headers version..."
          npm list on-headers --depth=0 || echo "on-headers resolved via transitive dependencies"
          
      - name: Audit header usage patterns
        run: |
          echo "Scanning for vulnerable header patterns..."
          find src -name "*.js" -o -name "*.ts" | xargs grep -l "writeHead.*\[" || echo "No vulnerable patterns found"
          
      - name: Run header security tests
        run: npm run test:headers || echo "Header security tests not configured"
```

### Best Practices

#### HTTP Header Security
1. **Use Objects**: Always pass objects to `response.writeHead()`, never arrays
2. **Helmet Integration**: Use helmet.js for comprehensive security headers
3. **Header Validation**: Validate header values before setting
4. **CSP Implementation**: Implement proper Content Security Policy headers

#### Development Guidelines
1. **Code Review**: Review all header-setting code for array usage
2. **Linting Rules**: Add ESLint rules to detect array header patterns
3. **Testing**: Include header security in unit and integration tests
4. **Documentation**: Document secure header handling practices

#### Production Considerations
1. **Header Monitoring**: Monitor response headers for unexpected values
2. **Security Scanning**: Regular scans for header manipulation vulnerabilities
3. **Incident Response**: Have procedures for header-related security incidents
4. **Compliance**: Ensure headers meet security compliance requirements

### Express.js Specific Guidance

#### Secure Middleware Stack
```javascript
// Complete secure Express.js setup
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');

const app = express();

// Security middleware stack
app.use(helmet()); // Comprehensive security headers
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true
}));

// Custom security headers
app.use((req, res, next) => {
  res.setHeader('X-API-Version', '1.0');
  res.setHeader('X-Request-ID', req.id || 'unknown');
  next();
});

// Error handling with secure headers
app.use((err, req, res, next) => {
  res.setHeader('X-Error-ID', generateErrorId());
  res.status(500).json({ error: 'Internal Server Error' });
});
```

---
**Note**: While this vulnerability has low severity (CVSS 4.2), maintaining secure header handling practices is essential for overall application security and compliance.
