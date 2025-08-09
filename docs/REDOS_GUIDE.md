# ReDoS Vulnerability Guide

## What is ReDoS?
Regular Expression Denial of Service (ReDoS) is a vulnerability where poorly crafted regular expressions can cause exponential time complexity when processing malicious input, leading to CPU exhaustion and application hang.

## Common ReDoS Patterns

### Vulnerable Patterns
```regex
(a+)+$          # Nested quantifiers
(a|a)*$         # Alternation with overlap
(a+)+ b         # Quantified groups
\s*(?:([+-]?)\s*(\d+))?  # nth-check vulnerability
```

### Safe Alternatives
```regex
a+$             # Non-nested quantifiers
a*$             # Single quantifiers
[+-]?\d+        # Character classes instead of groups
```

## Detection Methods

### 1. Automated Testing
```bash
# Use ReDoS detection tools
npm install -g redos-detector
redos-detector /path/to/regex/file

# Use ESLint plugin
npm install eslint-plugin-security
# Add to .eslintrc: "security/detect-unsafe-regex"
```

### 2. Manual Testing
```javascript
// Test with exponentially growing input
function testReDoS(regex, baseInput, multiplier = 2) {
    for (let i = 1; i <= 20; i++) {
        const input = baseInput.repeat(i * multiplier);
        const start = Date.now();
        
        try {
            regex.test(input);
        } catch (e) {
            // Expected for invalid regex
        }
        
        const time = Date.now() - start;
        console.log(`Length ${input.length}: ${time}ms`);
        
        if (time > 1000) {
            console.log('⚠️  Potential ReDoS detected!');
            break;
        }
    }
}

// Example usage
testReDoS(/^(a+)+$/, 'a', 1000);
```

### 3. Performance Monitoring
```javascript
// Add timeout to regex operations
function safeRegexTest(regex, input, timeout = 1000) {
    const worker = new Worker(`
        const regex = ${regex};
        const result = regex.test('${input}');
        postMessage(result);
    `);
    
    return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
            worker.terminate();
            reject(new Error('ReDoS timeout'));
        }, timeout);
        
        worker.onmessage = (e) => {
            clearTimeout(timer);
            resolve(e.data);
        };
    });
}
```

## Prevention Strategies

### 1. Input Validation
```javascript
// Limit input length
function validateInput(input, maxLength = 1000) {
    if (input.length > maxLength) {
        throw new Error('Input too long');
    }
    return input;
}

// Sanitize special characters
function sanitizeRegexInput(input) {
    return input.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
```

### 2. Safe Regex Patterns
```javascript
// Instead of: /^(a+)+$/
// Use: /^a+$/

// Instead of: /^(a|a)*$/  
// Use: /^a*$/

// Instead of: /^\s*([+-]?\d+)\s*$/
// Use: /^\s*[+-]?\d+\s*$/
```

### 3. Timeout Mechanisms
```javascript
// Node.js with AbortController
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 1000);

try {
    // Use controller.signal with regex operations
    const result = performRegexOperation(input, { signal: controller.signal });
} finally {
    clearTimeout(timeout);
}
```

## Security Testing

### Unit Tests for ReDoS
```javascript
// Jest test example
describe('ReDoS Protection', () => {
    test('should not hang on malicious input', async () => {
        const maliciousInput = 'a'.repeat(50000) + '!';
        const start = Date.now();
        
        try {
            await processUserInput(maliciousInput);
        } catch (e) {
            // Expected
        }
        
        const elapsed = Date.now() - start;
        expect(elapsed).toBeLessThan(1000); // Should complete quickly
    });
});
```

### CI/CD Integration
```yaml
# Add to GitHub Actions
- name: ReDoS Security Test
  run: |
    npm test -- --testNamePattern="ReDoS"
    npm run test:security:redos
```

## Incident Response

### 1. Immediate Mitigation
- Rate limiting on affected endpoints
- Input length restrictions
- Circuit breaker patterns
- Temporary disable affected features

### 2. Long-term Fixes
- Update vulnerable dependencies
- Rewrite problematic regex patterns
- Add comprehensive input validation
- Implement monitoring and alerting

## Tools and Resources

### Detection Tools
- [redos-detector](https://www.npmjs.com/package/redos-detector)
- [safe-regex](https://www.npmjs.com/package/safe-regex)
- [eslint-plugin-security](https://www.npmjs.com/package/eslint-plugin-security)

### Online Resources
- [OWASP ReDoS Guide](https://owasp.org/www-community/attacks/Regular_expression_Denial_of_Service_-_ReDoS)
- [Regular Expression Security](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html#regular-expression-considerations)
- [ReDoS Testing Tool](https://jex.im/regulex/)

### CVE References
- CVE-2021-3803 (nth-check)
- CVE-2019-20149 (kind-of)
- CVE-2021-23382 (postcss-resolve-nested-selector)
