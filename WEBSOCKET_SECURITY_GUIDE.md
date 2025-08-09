# WebSocket Security Guide

## webpack-dev-server Source Code Exposure Prevention

### Vulnerability Overview (CVE-2018-14732)
webpack-dev-server versions <= 5.2.0 contain a critical vulnerability that allows malicious websites to steal source code through Cross-site WebSocket hijacking, particularly affecting non-Chromium browsers.

### Attack Vector
1. **Target**: Development servers using webpack-dev-server on predictable ports
2. **Method**: Multiple attack vectors identified:
   - **WebSocket Hijacking**: Malicious websites exploit IP address Origin header allowance
   - **Script Injection**: Cross-site script loading combined with prototype pollution
3. **Impact**: Complete source code exposure via webpack module extraction
4. **Affected Browsers**: Non-Chromium browsers (Firefox, Safari, etc.) and all browsers for script injection attacks

### Prevention Measures

#### 1. Immediate Fix ✅
```json
{
  "resolutions": {
    "webpack-dev-server": ">=5.2.1"
  },
  "overrides": {
    "webpack-dev-server": ">=5.2.1"
  }
}
```

#### 2. Development Environment Security
```bash
# Use localhost instead of IP addresses
npx webpack-dev-server --host localhost

# Enable HTTPS for development
npx webpack-dev-server --https

# Use random ports instead of predictable ones
npx webpack-dev-server --port 0

# Disable host checking (use with caution)
npx webpack-dev-server --disable-host-check false
```

#### 3. Script Injection Protection
```javascript
// webpack.config.js - Disable HMR in production-like environments
module.exports = {
  devServer: {
    hot: process.env.NODE_ENV === 'development',
    liveReload: process.env.NODE_ENV === 'development',
    // Restrict access to specific hosts
    allowedHosts: ['localhost', '.localhost'],
    // Enhanced security headers
    headers: {
      'X-Frame-Options': 'DENY',
      'X-Content-Type-Options': 'nosniff',
      'X-XSS-Protection': '1; mode=block'
    }
  }
};
```

#### 3. Network Security
- **Firewall Rules**: Block external access to development ports (8080, 3000, etc.)
- **VPN Usage**: Access development servers only through secure VPN
- **Browser Choice**: Use Chromium-based browsers for development (Chrome 94+)
- **Host Restrictions**: Configure webpack-dev-server with allowedHosts whitelist

### Detection Methods

#### 1. Vulnerability Scanning
```bash
# Check current webpack-dev-server version
npm list webpack-dev-server

# Audit for vulnerabilities
npm audit --audit-level high
```

#### 2. Network Monitoring
```bash
# Monitor WebSocket connections
netstat -tulpn | grep :8080

# Check for suspicious connections
ss -tuln | grep webpack
```

### Incident Response

#### If Exploitation Suspected:
1. **Immediate Actions**:
   - Stop webpack-dev-server immediately
   - Disconnect from any untrusted networks
   - Clear browser cache and cookies
   - Change all development ports

2. **Investigation**:
   - Check browser history for visited malicious sites
   - Review webpack build outputs for unauthorized modifications
   - Scan for unauthorized code access or data exfiltration
   - Check network logs for suspicious script requests

3. **Recovery**:
   - Update webpack-dev-server to >= 5.2.1
   - Implement host restrictions and security headers
   - Rotate any exposed secrets or API keys
   - Review and strengthen development environment security

### Best Practices

#### Development Security
- Never expose development servers to public internet
- Use HTTPS even in development
- Implement proper CORS policies
- Regular dependency updates and vulnerability scanning

#### Code Protection
- Avoid including sensitive data in development builds
- Use environment variables for secrets
- Implement proper access controls

#### Browser Security
- Keep browsers updated
- Use Chromium-based browsers for development
- Enable security features and disable unnecessary plugins

### Testing for Vulnerability

#### Safe Testing Script
```javascript
// Test if webpack-dev-server is properly secured
function testWebpackSecurity() {
  console.log('Testing webpack-dev-server security...');
  
  // Test 1: WebSocket connection security
  try {
    const ws = new WebSocket('ws://localhost:8080/ws');
    ws.onopen = () => {
      console.log('❌ WebSocket connection possible - check security');
      ws.close();
    };
    ws.onerror = () => {
      console.log('✅ WebSocket connection blocked - good security');
    };
  } catch (error) {
    console.log('✅ WebSocket blocked by browser security - secure');
  }
  
  // Test 2: Script injection protection
  try {
    const script = document.createElement('script');
    script.src = 'http://localhost:8080/main.js';
    script.onload = () => {
      console.log('❌ Script loading possible - verify webpack configuration');
    };
    script.onerror = () => {
      console.log('✅ Script loading blocked - good protection');
    };
    // Don't actually append to avoid real exploitation
    console.log('Script injection test prepared (not executed for safety)');
  } catch (error) {
    console.log('✅ Script injection blocked - secure configuration');
  }
}

// testWebpackSecurity(); // Uncomment to run test
```

### Compliance and Reporting

#### Security Standards
- Follow OWASP WebSocket Security Guidelines
- Implement CSP headers for WebSocket connections
- Regular security audits and penetration testing

#### Incident Documentation
- Log all security-related configuration changes
- Maintain vulnerability response timeline
- Update security policies based on lessons learned

### Additional Resources
- [OWASP WebSocket Security](https://owasp.org/www-community/attacks/WebSocket_Attacks)
- [webpack-dev-server Security Configuration](https://webpack.js.org/configuration/dev-server/)
- [Browser Security Features](https://developer.mozilla.org/en-US/docs/Web/Security)

---
**Note**: This guide should be reviewed and updated regularly as new vulnerabilities and security measures are discovered.
