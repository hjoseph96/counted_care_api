# Google OAuth Flow Implementation

This document describes the new Google OAuth flow implemented in the Counted Care API.

## Overview

The API now supports a proper OAuth 2.0 flow for Google authentication, replacing the previous token-based approach. This provides better security and follows OAuth 2.0 standards.

## OAuth Flow

### Redirect Options

The API provides two ways to initiate the OAuth flow:

1. **JSON Response**: Get the OAuth URL and handle redirect manually
2. **Automatic Redirect**: Let the API handle the redirect automatically

**Automatic Redirect Endpoints:**
- `GET /api/v1/oauth/google?redirect=true` - Redirects to Google OAuth
- `GET /api/v1/oauth/google/redirect` - Dedicated redirect endpoint

### 1. Initiate OAuth Flow

**Endpoint:** `GET /api/v1/oauth/google`

**Description:** Initiates the Google OAuth flow by generating a secure state parameter and returning the Google OAuth URL.

**Response:**
```json
{
  "status": "success",
  "data": {
    "oauth_url": "https://accounts.google.com/o/oauth2/v2/auth?client_id=...&redirect_uri=...&scope=email+profile&response_type=code&state=...&access_type=offline&prompt=consent",
    "state": "generated_state_parameter"
  }
}
```

**OAuth URL Parameters:**
- `client_id`: Your Google OAuth client ID
- `redirect_uri`: Callback URL for your application
- `scope`: Requested permissions (email and profile)
- `response_type`: Set to "code" for authorization code flow
- `state`: Security parameter to prevent CSRF attacks
- `access_type`: Set to "offline" to get refresh tokens
- `prompt`: Set to "consent" to always show consent screen

**Frontend Usage:**

**Method 1: Get OAuth URL and Redirect Manually**
```javascript
// 1. Get OAuth URL from API
const response = await fetch('/api/v1/oauth/google');
const { oauth_url, state } = await response.json();

// 2. Store state in localStorage for verification
localStorage.setItem('oauth_state', state);

// 3. Redirect user to Google OAuth
window.location.href = oauth_url;
```

**Method 2: Automatic Redirect**
```javascript
// Automatic redirect to Google OAuth
window.location.href = '/api/v1/oauth/google?redirect=true';

// Or use the dedicated redirect endpoint
window.location.href = '/api/v1/oauth/google/redirect';
```

### 2. Handle OAuth Callback

**Endpoint:** `GET /api/v1/oauth/google/callback`

**Description:** Handles the callback from Google OAuth, exchanges the authorization code for an access token, retrieves user information, and creates/updates the user account.

**Parameters:**
- `code` (required): Authorization code from Google
- `state` (required): State parameter for security verification

**Response (Success):**
```json
{
  "status": "success",
  "message": "Google OAuth successful",
  "data": {
    "user": {
      "id": 123,
      "email": "user@example.com",
      "name": "User Name"
    },
    "token": "jwt_token_here"
  }
}
```

**Response (Error - Invalid State):**
```json
{
  "status": "error",
  "message": "Invalid OAuth state parameter",
  "code": "INVALID_OAUTH_STATE"
}
```

**Response (Error - Missing Code):**
```json
{
  "status": "error",
  "message": "Authorization code is required",
  "code": "MISSING_AUTH_CODE"
}
```

**Frontend Usage:**
```javascript
// After Google redirects back to your app
const urlParams = new URLSearchParams(window.location.search);
const code = urlParams.get('code');
const state = urlParams.get('state');

// Verify state parameter
const storedState = localStorage.getItem('oauth_state');
if (state !== storedState) {
  console.error('Invalid OAuth state');
  return;
}

// Exchange code for user data and token
const response = await fetch('/api/v1/oauth/google/callback', {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json'
  }
});

const result = await response.json();

if (result.status === 'success') {
  // Store token and user data
  localStorage.setItem('countedcare-auth-token', result.data.token);
  localStorage.setItem('countedcare-user-id', result.data.user.id);
  
  // Clear OAuth state
  localStorage.removeItem('oauth_state');
  
  // Redirect to dashboard or home page
  window.location.href = '/dashboard';
} else {
  console.error('OAuth failed:', result.message);
}
```

## Security Features

### State Parameter Verification
- Each OAuth initiation generates a unique state parameter
- The state is stored in the server session
- Callback verification ensures the state matches
- Prevents CSRF attacks and replay attacks

### Rate Limiting
- OAuth initiation: 20 requests per hour per IP
- OAuth callback: 50 requests per hour per IP
- Automatic blocking of excessive requests

### Session Management
- OAuth state is stored in secure server sessions
- State is automatically cleared after successful callback
- Sessions are protected against tampering

## Configuration

### Google OAuth Credentials
The following credentials must be configured in `config/credentials.yml.enc`:

```yaml
google:
  client_id: "your_google_client_id"
  secret_access_key: "your_google_client_secret"
```

### Redirect URI Configuration
In your Google Cloud Console, configure the authorized redirect URI:

```
https://yourdomain.com/api/v1/oauth/google/callback
```

For development:
```
http://localhost:3000/api/v1/oauth/google/callback
```

## Error Handling

### Common Error Codes

- `INVALID_OAUTH_STATE`: State parameter mismatch or missing
- `MISSING_AUTH_CODE`: Authorization code not provided
- `OAUTH_ERROR`: General OAuth processing error

### Error Response Format
All errors follow the standard API error format:
```json
{
  "status": "error",
  "message": "Human readable error message",
  "code": "ERROR_CODE"
}
```

## Migration from Token-Based Approach

### Old Approach (Deprecated)
```javascript
// Old way - sending Google ID token directly
const response = await fetch('/api/v1/auth/google', {
  method: 'POST',
  body: JSON.stringify({ token: googleIdToken })
});
```

### New Approach (Recommended)
```javascript
// New way - proper OAuth flow
const response = await fetch('/api/v1/oauth/google');
const { oauth_url } = await response.json();
window.location.href = oauth_url;
```

## Testing

### Test Environment
- OAuth flow is disabled in test environment
- Tests use mocked HTTP responses
- Session state is properly managed in tests

### Running Tests
```bash
# Run OAuth tests only
bundle exec rspec spec/requests/api/v1/oauth_spec.rb

# Run all tests
bundle exec rspec
```

## Production Considerations

### HTTPS Required
- OAuth flow requires HTTPS in production
- Google OAuth endpoints are HTTPS-only
- Ensure proper SSL certificate configuration

### Session Security
- Sessions are stored in secure cookies
- Consider using Redis for session storage in production
- Implement proper session expiration

### Monitoring
- Monitor OAuth success/failure rates
- Track rate limiting events
- Log OAuth errors for debugging

## Troubleshooting

### Common Issues

1. **Invalid Redirect URI**
   - Verify redirect URI in Google Cloud Console
   - Check for trailing slashes or protocol mismatches

2. **State Parameter Errors**
   - Ensure sessions are properly configured
   - Check for session middleware configuration

3. **Rate Limiting**
   - Monitor rate limit headers in responses
   - Implement exponential backoff for retries

4. **Session Issues**
   - Verify session middleware is enabled
   - Check cookie configuration
   - Ensure proper session storage

### Debug Mode
Enable debug logging in development:
```ruby
# config/environments/development.rb
config.log_level = :debug
```

## User Data Endpoint

### GET /api/v1/auth/me

**Description:** Retrieves the current authenticated user's data.

**Authentication:** Requires valid JWT token in Authorization header.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Response (Success):**
```json
{
  "id": 123,
  "email": "user@example.com",
  "name": "User Name",
  "provider": "google_oauth2",
  "uid": "google_uid_123",
  "created_at": "2024-01-01T00:00:00.000Z",
  "updated_at": "2024-01-01T00:00:00.000Z"
}
```

**Response (Unauthorized):**
```json
{
  "status": "error",
  "message": "Unauthorized. Valid JWT token required."
}
```

**Frontend Usage:**
```javascript
// Refresh user data
static async refreshUserData() {
  try {
    const response = await authClient.get('/api/v1/auth/me');
    const user = response.data;
    
    // Update localStorage with fresh user ID
    if (user.id) {
      localStorage.setItem('countedcare-user-id', user.id);
    }
    
    return user;
  } catch (error) {
    console.error('Error refreshing user data:', error);
    return null;
  }
}
```

**Rate Limiting:**
- IP-based: 1000 requests per hour
- User-based: 1000 requests per hour

## Support

For issues or questions about the OAuth implementation:
1. Check the logs for detailed error messages
2. Verify Google OAuth configuration
3. Test with the provided examples
4. Review rate limiting and session configuration
