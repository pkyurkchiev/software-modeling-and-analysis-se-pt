# Simple YouTube SQL Software Modeling

This repository contains a simplified SQL schema for modeling a YouTube-like system, focusing on how to structure and manage user-generated content, subscriptions, playlists, video categories, and more. The SQL code includes schema definitions, table creation, relationships between tables, stored procedures, functions, and triggers to manage typical interactions in such a system.

## Features

- **User Management**:
  - Tables: `UserAccount`, `Subscription`, `Playlist`
  - Manages user details, subscriptions, and playlists.

- **Content Management**:
  - Tables: `Video`, `Categories`, `Comments`, `Likes`, `PlaylistVideo`
  - Models videos, their categories, comments, likes, and playlists.

- **Stored Procedures**:
  - Add new users, upload videos, and define video categories.

- **Functions**:
  - Calculate video duration in minutes, get total videos by a user, and manage subscriber counts.

- **Triggers**:
  - Automatically updates subscriber counts on subscription or unsubscription events.

## Database Schema

### User Management Schema

- **UserAccount**: Stores user details including username, email, and phone number.
- **Subscription**: Tracks user-to-user subscriptions.
- **Playlist**: Represents user-created playlists.

### Content Management Schema

- **Video**: Stores information about videos including URL, title, duration, and genre.
- **Categories**: Defines genres of videos (e.g., Education, Entertainment).
- **Comments**: Allows users to comment on videos.
- **Likes**: Allows users to like or dislike videos.
- **PlaylistVideo**: Links videos to user playlists.

### Diagram

- Chen's Notation Diagram
![Chen's Notation Diagram.png](Chen%27s%20Notation%20Diagram.png)



- Crow's Notation Diagram
![Crow's Notation Diagram.png](Crow%27s%20Notation%20Diagram.png)



- Data Warehouse Diagram
![YoutubeDataWarehouseDiagram.drawio.png](YoutubeDataWarehouseDiagram.drawio.png)