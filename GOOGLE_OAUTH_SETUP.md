# Google OAuth Setup Guide

## Rails Credentials

The Google OAuth credentials are stored securely in Rails credentials. To add or update them:

```bash
# Edit credentials (this will open your default editor)
bin/rails credentials:edit

# Add the following structure:
google:
  client_id: your_google_client_id_here
  client_secret: your_google_client_secret_here
```

## Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google+ API
4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client IDs"
5. Set the application type to "Web application"
6. Add authorized redirect URIs:
   - `http://localhost:3000/api/v1/auth/google/callback` (for development)
   - `https://yourdomain.com/api/v1/auth/google/callback` (for production)
7. Copy the Client ID and Client Secret to your `.env` file

## Usage

### Get OAuth URL
```
GET /api/v1/auth/google
```

This returns a Google OAuth URL that the frontend can redirect users to.

### OAuth Callback
```
GET /api/v1/auth/google/callback
```

This endpoint handles the OAuth callback from Google and creates/authenticates users.

## Authentication Flow

1. Frontend calls `/api/v1/auth/google` to get the OAuth URL
2. User is redirected to Google for authentication
3. Google redirects back to `/api/v1/auth/google/callback`
4. User is created/authenticated and returned with user data
5. Frontend can store the user session/token

## Security Notes

- Never commit your `.env` file to version control
- Use HTTPS in production
- Consider implementing JWT tokens for stateless authentication
- Validate OAuth state parameters to prevent CSRF attacks 