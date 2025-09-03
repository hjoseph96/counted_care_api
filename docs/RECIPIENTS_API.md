# Recipients API Documentation

This document describes the Recipients API endpoints for managing care recipients in the Counted Care application.

## Overview

The Recipients API allows authenticated users to manage their care recipients, including creating, updating, and retrieving a paginated list of recipients. All endpoints require JWT authentication and include rate limiting.

## Authentication

All endpoints require a valid JWT token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

## Endpoints

### GET /api/v1/recipients

Retrieves a paginated list of care recipients belonging to the authenticated user.

**Parameters:**
- `page` (optional): Page number for pagination (default: 1)
- `per_page` (optional): Number of recipients per page (default: 25)

**Response (Success - 200 OK):**
```json
{
  "status": "success",
  "data": {
    "recipients": [
      {
        "id": "uuid-here",
        "name": "John Doe",
        "relationship": "Father",
        "insurance_info": "Blue Cross Blue Shield",
        "conditions": ["Diabetes", "Hypertension"],
        "created_at": "2024-01-01T00:00:00.000Z",
        "updated_at": "2024-01-01T00:00:00.000Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 1,
      "total_count": 3,
      "per_page": 25,
      "next_page": null,
      "prev_page": null
    }
  }
}
```

**Response (Unauthorized - 401):**
```json
{
  "status": "error",
  "message": "Unauthorized. Valid JWT token required."
}
```

**Frontend Usage:**
```javascript
// Get paginated list of recipients
const getRecipients = async (page = 1, perPage = 25) => {
  try {
    const response = await authClient.get('/api/v1/recipients', {
      params: { page, per_page: perPage }
    });
    return response.data;
  } catch (error) {
    console.error('Error fetching recipients:', error);
    throw error;
  }
};

// Example usage
const { recipients, pagination } = await getRecipients(1, 10);
console.log(`Showing ${recipients.length} of ${pagination.total_count} recipients`);
```

### POST /api/v1/recipients

Creates a new care recipient for the authenticated user.

**Request Body:**
```json
{
  "recipient": {
    "name": "John Doe",
    "relationship": "Father",
    "insurance_info": "Blue Cross Blue Shield",
    "conditions": ["Diabetes", "Hypertension"]
  }
}
```

**Required Fields:**
- `name`: Recipient's full name
- `relationship`: Relationship to the user (e.g., "Father", "Mother", "Spouse")

**Optional Fields:**
- `insurance_info`: Insurance provider information
- `conditions`: Array of medical conditions

**Response (Success - 201 Created):**
```json
{
  "status": "success",
  "message": "Care recipient created successfully",
  "data": {
    "id": "uuid-here",
    "name": "John Doe",
    "relationship": "Father",
    "insurance_info": "Blue Cross Blue Shield",
    "conditions": ["Diabetes", "Hypertension"],
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-01T00:00:00.000Z"
  }
}
```

**Response (Validation Error - 422):**
```json
{
  "status": "error",
  "message": "Failed to create care recipient",
  "errors": ["Name can't be blank", "Relationship can't be blank"]
}
```

**Frontend Usage:**
```javascript
// Create a new care recipient
const createRecipient = async (recipientData) => {
  try {
    const response = await authClient.post('/api/v1/recipients', {
      recipient: recipientData
    });
    return response.data;
  } catch (error) {
    console.error('Error creating recipient:', error);
    throw error;
  }
};

// Example usage
const newRecipient = await createRecipient({
  name: 'Jane Doe',
  relationship: 'Mother',
  insurance_info: 'Aetna',
  conditions: ['Arthritis']
});
```

### PATCH /api/v1/recipients/:id

Updates an existing care recipient belonging to the authenticated user.

**Parameters:**
- `id`: UUID of the care recipient to update

**Request Body:**
```json
{
  "recipient": {
    "name": "Updated Name",
    "insurance_info": "Updated Insurance"
  }
}
```

**Response (Success - 200 OK):**
```json
{
  "status": "success",
  "message": "Care recipient updated successfully",
  "data": {
    "id": "uuid-here",
    "name": "Updated Name",
    "relationship": "Father",
    "insurance_info": "Updated Insurance",
    "conditions": ["Diabetes", "Hypertension"],
    "created_at": "2024-01-01T00:00:00.000Z",
    "updated_at": "2024-01-01T00:00:00.000Z"
  }
}
```

**Response (Not Found - 404):**
```json
{
  "status": "error",
  "message": "Couldn't find CareRecipient"
}
```

**Response (Validation Error - 422):**
```json
{
  "status": "error",
  "message": "Failed to update care recipient",
  "errors": ["Name can't be blank"]
}
```

**Frontend Usage:**
```javascript
// Update an existing care recipient
const updateRecipient = async (id, updates) => {
  try {
    const response = await authClient.patch(`/api/v1/recipients/${id}`, {
      recipient: updates
    });
    return response.data;
  } catch (error) {
    console.error('Error updating recipient:', error);
    throw error;
  }
};

// Example usage
const updatedRecipient = await updateRecipient(recipientId, {
  insurance_info: 'New Insurance Provider'
});
```

## Data Models

### CareRecipient

```ruby
class CareRecipient < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :destroy
  
  validates :name, presence: true
  validates :relationship, presence: true
end
```

**Attributes:**
- `id`: UUID primary key
- `name`: String (required)
- `relationship`: String (required)
- `insurance_info`: String (optional)
- `conditions`: Array of strings (optional)
- `user_id`: UUID foreign key to User
- `created_at`: Timestamp
- `updated_at`: Timestamp

## Rate Limiting

The API implements rate limiting to prevent abuse:

**IP-based Limits:**
- Index: 1000 requests per hour
- Create: 100 requests per hour
- Update: 200 requests per hour

**User-based Limits:**
- Index: 2000 requests per hour
- Create: 200 requests per hour
- Update: 500 requests per hour

**Rate Limit Headers:**
```
X-RateLimit-Limit-IP: 1000
X-RateLimit-Remaining-IP: 999
X-RateLimit-Reset-IP: 1640995200
X-RateLimit-Limit-User: 2000
X-RateLimit-Remaining-User: 1999
X-RateLimit-Reset-User: 1640995200
```

## Error Handling

All endpoints return consistent error responses:

**Common Error Codes:**
- `401 Unauthorized`: Invalid or missing JWT token
- `404 Not Found`: Resource not found or doesn't belong to user
- `422 Unprocessable Entity`: Validation errors
- `429 Too Many Requests`: Rate limit exceeded

**Error Response Format:**
```json
{
  "status": "error",
  "message": "Human readable error message",
  "errors": ["Detailed error messages"] // For validation errors
}
```

## Security Features

1. **JWT Authentication**: All endpoints require valid JWT tokens
2. **User Isolation**: Users can only access their own care recipients
3. **Rate Limiting**: Prevents abuse and ensures fair usage
4. **Input Validation**: Server-side validation of all input data
5. **SQL Injection Protection**: Uses parameterized queries

## Pagination

The index endpoint supports pagination with the following features:

- **Default page size**: 25 recipients per page
- **Customizable page size**: Up to 100 recipients per page
- **Page navigation**: Previous/next page information
- **Total count**: Total number of recipients across all pages

**Pagination Parameters:**
- `page`: Current page number (1-based)
- `per_page`: Number of items per page (1-100)

## Testing

The API includes comprehensive test coverage:

- **Authentication tests**: Valid/invalid token scenarios
- **CRUD operations**: Create, read, update functionality
- **Validation tests**: Required field validation
- **Authorization tests**: User isolation verification
- **Rate limiting tests**: Rate limit enforcement
- **Pagination tests**: Page and per_page functionality

Run tests with:
```bash
# Run all recipients tests
bundle exec rspec spec/requests/api/v1/recipients_spec.rb

# Run all API tests
bundle exec rspec spec/requests/api/v1/

# Run full test suite
bundle exec rspec
```

## Example Frontend Implementation

```javascript
class RecipientsService {
  constructor(authClient) {
    this.client = authClient;
  }

  // Get paginated list of recipients
  async getRecipients(page = 1, perPage = 25) {
    const response = await this.client.get('/api/v1/recipients', {
      params: { page, per_page: perPage }
    });
    return response.data;
  }

  // Create new recipient
  async createRecipient(recipientData) {
    const response = await this.client.post('/api/v1/recipients', {
      recipient: recipientData
    });
    return response.data;
  }

  // Update existing recipient
  async updateRecipient(id, updates) {
    const response = await this.client.patch(`/api/v1/recipients/${id}`, {
      recipient: updates
    });
    return response.data;
  }

  // Delete recipient (if implemented)
  async deleteRecipient(id) {
    const response = await this.client.delete(`/api/v1/recipients/${id}`);
    return response.data;
  }
}

// Usage
const recipientsService = new RecipientsService(authClient);

// Get first page of recipients
const { recipients, pagination } = await recipientsService.getRecipients(1, 10);

// Create new recipient
const newRecipient = await recipientsService.createRecipient({
  name: 'John Doe',
  relationship: 'Father',
  insurance_info: 'Blue Cross Blue Shield'
});
```

## Support

For issues or questions about the Recipients API:

1. Check the logs for detailed error messages
2. Verify JWT token validity and expiration
3. Review rate limiting configuration
4. Test with the provided examples
5. Check the test suite for expected behavior
