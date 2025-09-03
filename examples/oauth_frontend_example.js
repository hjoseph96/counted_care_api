// Google OAuth Flow Frontend Implementation
// This example shows how to implement the new OAuth flow in your frontend

class GoogleOAuth {
  constructor() {
    this.apiBase = '/api/v1';
    this.stateKey = 'oauth_state';
  }

  // Step 1: Initiate OAuth flow
  async initiateOAuth() {
    try {
      console.log('Initiating Google OAuth flow...');
      
      // Get OAuth URL from API
      const response = await fetch(`${this.apiBase}/oauth/google`);
      const data = await response.json();
      
      if (data.status === 'success') {
        // Store state parameter for verification
        localStorage.setItem(this.stateKey, data.data.state);
        
        // Store OAuth URL
        const oauthUrl = data.data.oauth_url;
        
        console.log('OAuth URL received, redirecting to Google...');
        
        // Redirect user to Google OAuth
        window.location.href = oauthUrl;
      } else {
        throw new Error('Failed to get OAuth URL');
      }
    } catch (error) {
      console.error('Error initiating OAuth:', error);
      throw error;
    }
  }

  // Step 2: Handle OAuth callback (called when user returns from Google)
  async handleCallback() {
    try {
      console.log('Handling OAuth callback...');
      
      // Get URL parameters
      const urlParams = new URLSearchParams(window.location.search);
      const code = urlParams.get('code');
      const state = urlParams.get('state');
      
      if (!code || !state) {
        throw new Error('Missing OAuth parameters');
      }
      
      // Verify state parameter
      const storedState = localStorage.getItem(this.stateKey);
      if (state !== storedState) {
        throw new Error('Invalid OAuth state parameter');
      }
      
      console.log('State verified, exchanging code for token...');
      
      // Exchange authorization code for user data and token
      const response = await fetch(`${this.apiBase}/oauth/google/callback?code=${code}&state=${state}`);
      const result = await response.json();
      
      if (result.status === 'success') {
        console.log('OAuth successful, storing user data...');
        
        // Store authentication data
        localStorage.setItem('countedcare-auth-token', result.data.token);
        localStorage.setItem('countedcare-user-id', result.data.user.id);
        localStorage.setItem('countedcare-user-email', result.data.user.email);
        localStorage.setItem('countedcare-user-name', result.data.user.name);
        
        // Clear OAuth state
        localStorage.removeItem(this.stateKey);
        
        // Clear URL parameters
        window.history.replaceState({}, document.title, window.location.pathname);
        
        console.log('User authenticated successfully:', result.data.user);
        
        // Redirect to dashboard or home page
        this.redirectToDashboard();
        
        return result.data;
      } else {
        throw new Error(`OAuth failed: ${result.message}`);
      }
    } catch (error) {
      console.error('Error handling OAuth callback:', error);
      
      // Clear any stored OAuth data
      localStorage.removeItem(this.stateKey);
      
      // Redirect to error page or show error message
      this.showError(error.message);
      
      throw error;
    }
  }

  // Check if user is returning from OAuth
  isOAuthCallback() {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.has('code') && urlParams.has('state');
  }

  // Redirect to dashboard after successful authentication
  redirectToDashboard() {
    // Replace with your dashboard URL
    window.location.href = '/dashboard';
  }

  // Show error message
  showError(message) {
    // Replace with your error handling logic
    alert(`OAuth Error: ${message}`);
  }

  // Check if user is authenticated
  isAuthenticated() {
    return localStorage.getItem('countedcare-auth-token') !== null;
  }

  // Get current user data
  getCurrentUser() {
    if (!this.isAuthenticated()) {
      return null;
    }
    
    return {
      id: localStorage.getItem('countedcare-user-id'),
      email: localStorage.getItem('countedcare-user-email'),
      name: localStorage.getItem('countedcare-user-name')
    };
  }

  // Sign out
  signOut() {
    localStorage.removeItem('countedcare-auth-token');
    localStorage.removeItem('countedcare-user-id');
    localStorage.removeItem('countedcare-user-email');
    localStorage.removeItem('countedcare-user-name');
    
    // Redirect to home page
    window.location.href = '/';
  }
}

// Usage Examples

// 1. Initialize OAuth flow
function signInWithGoogle() {
  const oauth = new GoogleOAuth();
  oauth.initiateOAuth();
}

// 2. Handle OAuth callback (call this when page loads)
function initializeOAuth() {
  const oauth = new GoogleOAuth();
  
  if (oauth.isOAuthCallback()) {
    oauth.handleCallback();
  }
}

// 3. Check authentication status
function checkAuthStatus() {
  const oauth = new GoogleOAuth();
  
  if (oauth.isAuthenticated()) {
    const user = oauth.getCurrentUser();
    console.log('User is authenticated:', user);
    
    // Show authenticated UI
    showAuthenticatedUI(user);
  } else {
    console.log('User is not authenticated');
    
    // Show sign-in UI
    showSignInUI();
  }
}

// 4. Sign out
function signOut() {
  const oauth = new GoogleOAuth();
  oauth.signOut();
}

// UI Helper Functions (replace with your actual UI logic)
function showAuthenticatedUI(user) {
  // Hide sign-in button, show user info, etc.
  console.log('Showing authenticated UI for:', user.name);
}

function showSignInUI() {
  // Show sign-in button, hide user info, etc.
  console.log('Showing sign-in UI');
}

// Initialize OAuth when page loads
document.addEventListener('DOMContentLoaded', function() {
  initializeOAuth();
  checkAuthStatus();
});

// Example button click handlers
document.getElementById('google-signin-btn')?.addEventListener('click', signInWithGoogle);
document.getElementById('signout-btn')?.addEventListener('click', signOut);
