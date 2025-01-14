# Multiplayer Sessions Design

## Current Implementation
- Basic client-server networking using ENet
- Server registration/deregistration with GameLift FleetIQ via Lambda
- Direct connection to server using hardcoded localhost:6060

## Required Changes

### 1. Game Session Management
- Create new DynamoDB table schema for game sessions:
  ```json
  {
    "session_id": "string (primary key)",
    "host_id": "string",
    "session_state": "string (WAITING, CONNECTING, IN_PROGRESS)",
    "player_count": "number",
    "max_players": "number",
    "connected_players": "list",
    "server_id": "string (null until assigned)",
    "server_endpoint": "string (null until assigned)"
  }
  ```

### 2. Server-Side Lambda Functions Needed
1. `CreateGameSession` - Creates waiting room entry in DynamoDB
2. `ListGameSessions` - Returns available sessions in WAITING state
3. `JoinGameSession` - Adds player to session's connected_players
4. `StartGameSession` - Claims GameLift server and updates session with connection details
5. `LeaveGameSession` - Removes player from session
6. `CleanupGameSession` - Removes session when complete

### 3. Client-Side Changes Needed
1. Modify menu.gd:
   - Add "Host Game" button/UI
   - Add "Browse Games" button/UI
   - Add session browser UI
   - Add waiting room UI

2. Create new SessionManager autoload:
   - Handle AWS API communication
   - Manage current session state
   - Handle session lifecycle

3. Update MultiplayerManager:
   - Remove hardcoded connection details
   - Add session-based connection logic
   - Support reconnection to active session

### Questions for Clarification
1. What is the maximum number of players per session?
2. Should we support reconnecting to an active session?
3. Do we need to handle session timeouts for inactive waiting rooms?
4. Should we add password protection for private sessions?

## Implementation Plan
1. Create SessionManager singleton
2. Implement Lambda functions for session management
3. Create session browser and waiting room UI
4. Update MultiplayerManager for session-based connections
5. Add error handling and reconnection logic
6. Test full session lifecycle

Would you like me to proceed with implementing these changes after confirming the approach?