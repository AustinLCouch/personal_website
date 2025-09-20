-- Create projects table
CREATE TABLE projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    slug TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    short_desc TEXT NOT NULL,
    long_desc TEXT NOT NULL,
    github_url TEXT,
    live_url TEXT,
    featured BOOLEAN NOT NULL DEFAULT FALSE,
    tags TEXT, -- JSON array as text
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create index on slug for fast lookups
CREATE INDEX idx_projects_slug ON projects(slug);

-- Create index on category for filtering
CREATE INDEX idx_projects_category ON projects(category);

-- Create index on featured for homepage queries
CREATE INDEX idx_projects_featured ON projects(featured);

-- Create trigger to update updated_at
CREATE TRIGGER update_projects_updated_at 
AFTER UPDATE ON projects
BEGIN
    UPDATE projects SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
