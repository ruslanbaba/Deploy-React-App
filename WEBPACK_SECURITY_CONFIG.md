# Webpack Security Configuration Guide

## Secure webpack-dev-server Configuration

### Basic Security Configuration
```javascript
// webpack.config.js
const path = require('path');

module.exports = {
  mode: 'development',
  devServer: {
    // Host restrictions - only allow specific hosts
    allowedHosts: [
      'localhost',
      '.localhost',
      '127.0.0.1'
    ],
    
    // Network security
    host: 'localhost', // Never use 0.0.0.0 in development
    port: 0, // Use random port instead of predictable 8080
    
    // HTTPS enforcement
    https: process.env.WEBPACK_HTTPS === 'true',
    
    // Enhanced security headers
    headers: {
      'X-Frame-Options': 'DENY',
      'X-Content-Type-Options': 'nosniff',
      'X-XSS-Protection': '1; mode=block',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-eval'; style-src 'self' 'unsafe-inline';"
    },
    
    // Hot module replacement - disable in production-like environments
    hot: process.env.NODE_ENV === 'development',
    liveReload: process.env.NODE_ENV === 'development',
    
    // Client configuration
    client: {
      // Reduce log output
      logging: 'warn',
      // Disable overlay for production builds
      overlay: {
        errors: true,
        warnings: false
      }
    },
    
    // Static file serving security
    static: {
      directory: path.join(__dirname, 'public'),
      // Restrict access patterns
      serveIndex: false,
      // Security headers for static files
      staticOptions: {
        setHeaders: (res, path) => {
          res.setHeader('X-Content-Type-Options', 'nosniff');
          res.setHeader('X-Frame-Options', 'DENY');
        }
      }
    },
    
    // Webpack compilation security
    watchFiles: {
      // Restrict watch patterns to prevent directory traversal
      paths: ['src/**/*', 'public/**/*'],
      options: {
        ignored: /node_modules/
      }
    }
  },
  
  // Additional security configurations
  output: {
    // Prevent information disclosure
    pathinfo: false,
    // Clean output directory
    clean: true
  },
  
  // Module resolution security
  resolve: {
    // Prevent directory traversal
    symlinks: false,
    // Restrict module resolution
    fallback: {
      "fs": false,
      "path": false,
      "os": false
    }
  }
};
```

### Environment-Specific Configurations

#### Development Environment
```javascript
// webpack.dev.js
const { merge } = require('webpack-merge');
const common = require('./webpack.common.js');

module.exports = merge(common, {
  mode: 'development',
  devServer: {
    // Development-specific security
    host: 'localhost',
    port: 3000,
    https: false, // Can be false for local development
    hot: true,
    
    // Enhanced development security
    headers: {
      'Cross-Origin-Embedder-Policy': 'require-corp',
      'Cross-Origin-Opener-Policy': 'same-origin'
    }
  }
});
```

#### Production-like Testing
```javascript
// webpack.staging.js
const { merge } = require('webpack-merge');
const common = require('./webpack.common.js');

module.exports = merge(common, {
  mode: 'production',
  devServer: {
    // Production-like security
    host: 'localhost',
    port: 0, // Random port
    https: true, // Always HTTPS
    hot: false, // Disable HMR
    liveReload: false,
    
    // Strict security headers
    headers: {
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
      'Content-Security-Policy': "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self';"
    }
  }
});
```

### Package.json Scripts
```json
{
  "scripts": {
    "start": "webpack serve --config webpack.dev.js",
    "start:secure": "WEBPACK_HTTPS=true webpack serve --config webpack.dev.js",
    "start:staging": "webpack serve --config webpack.staging.js",
    "test:security": "npm run security:webpack && npm run security:deps",
    "security:webpack": "echo 'Testing webpack security configuration...' && node scripts/test-webpack-security.js",
    "security:deps": "npm audit --audit-level moderate"
  }
}
```

### Security Testing Script
```javascript
// scripts/test-webpack-security.js
const webpack = require('webpack');
const config = require('../webpack.config.js');

function testWebpackSecurity() {
  console.log('🔍 Testing webpack security configuration...');
  
  // Test 1: Check allowedHosts configuration
  if (config.devServer && config.devServer.allowedHosts) {
    const allowedHosts = config.devServer.allowedHosts;
    if (allowedHosts.includes('all') || allowedHosts.includes('auto')) {
      console.log('❌ WARNING: allowedHosts is too permissive');
    } else {
      console.log('✅ allowedHosts properly configured');
    }
  } else {
    console.log('❌ WARNING: allowedHosts not configured');
  }
  
  // Test 2: Check host configuration
  if (config.devServer && config.devServer.host) {
    if (config.devServer.host === '0.0.0.0') {
      console.log('❌ WARNING: Host set to 0.0.0.0 (insecure)');
    } else {
      console.log('✅ Host properly restricted');
    }
  }
  
  // Test 3: Check security headers
  if (config.devServer && config.devServer.headers) {
    const headers = config.devServer.headers;
    const requiredHeaders = ['X-Frame-Options', 'X-Content-Type-Options', 'X-XSS-Protection'];
    const missingHeaders = requiredHeaders.filter(header => !headers[header]);
    
    if (missingHeaders.length > 0) {
      console.log(`❌ WARNING: Missing security headers: ${missingHeaders.join(', ')}`);
    } else {
      console.log('✅ Security headers properly configured');
    }
  } else {
    console.log('❌ WARNING: No security headers configured');
  }
  
  // Test 4: Check HMR configuration
  if (config.devServer && config.devServer.hot !== false && process.env.NODE_ENV === 'production') {
    console.log('❌ WARNING: Hot module replacement enabled in production');
  } else {
    console.log('✅ HMR configuration appropriate for environment');
  }
  
  console.log('🔍 Webpack security test complete');
}

if (require.main === module) {
  testWebpackSecurity();
}

module.exports = testWebpackSecurity;
```

### Best Practices Checklist

#### ✅ Network Security
- [ ] Use `localhost` instead of `0.0.0.0` or IP addresses
- [ ] Configure `allowedHosts` whitelist
- [ ] Use random ports instead of predictable ones (8080, 3000)
- [ ] Enable HTTPS in production-like environments
- [ ] Implement proper firewall rules

#### ✅ Content Security
- [ ] Configure Content Security Policy headers
- [ ] Disable directory listing (`serveIndex: false`)
- [ ] Set proper MIME type headers
- [ ] Implement Cross-Origin policies

#### ✅ Development Security
- [ ] Disable HMR in production builds
- [ ] Restrict file watching patterns
- [ ] Clean output directories
- [ ] Disable symlink resolution

#### ✅ Monitoring
- [ ] Regular security audits (`npm audit`)
- [ ] Automated dependency scanning
- [ ] Configuration validation tests
- [ ] Network access monitoring

### Common Security Misconfigurations

#### ❌ Insecure Configurations
```javascript
// DON'T DO THIS
module.exports = {
  devServer: {
    host: '0.0.0.0', // Exposes to all network interfaces
    allowedHosts: 'all', // Allows any host
    port: 8080, // Predictable port
    https: false, // No encryption
    // No security headers
  }
};
```

#### ✅ Secure Configurations
```javascript
// DO THIS INSTEAD
module.exports = {
  devServer: {
    host: 'localhost',
    allowedHosts: ['localhost', '.localhost'],
    port: 0, // Random port
    https: true, // HTTPS enabled
    headers: {
      'X-Frame-Options': 'DENY',
      'X-Content-Type-Options': 'nosniff',
      'Content-Security-Policy': "default-src 'self'"
    }
  }
};
```

---
**Remember**: Security is an ongoing process. Regularly update webpack-dev-server and review your configuration as new vulnerabilities are discovered.
