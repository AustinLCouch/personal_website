use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};
use sqlx::{FromRow, SqlitePool};

use crate::Result;

#[derive(Debug, Clone, FromRow, Serialize, Deserialize)]
pub struct Project {
    pub id: i64,
    pub slug: String,
    pub title: String,
    pub category: String,
    pub short_desc: String,
    pub long_desc: String,
    pub github_url: Option<String>,
    pub live_url: Option<String>,
    pub featured: bool,
    pub tags: String, // JSON string
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

#[derive(Debug, Deserialize)]
pub struct ProjectQuery {
    pub category: Option<String>,
    pub featured: Option<bool>,
    pub limit: Option<i64>,
}

impl Project {
    /// Get all projects with optional filtering
    pub async fn all(pool: &SqlitePool, query: &ProjectQuery) -> Result<Vec<Project>> {
        let mut sql = "SELECT * FROM projects WHERE 1=1".to_string();
        let mut bind_params = Vec::new();

        if let Some(category) = &query.category {
            sql.push_str(" AND category = ?");
            bind_params.push(category.as_str());
        }

        if let Some(featured) = query.featured {
            sql.push_str(" AND featured = ?");
            bind_params.push(if featured { "1" } else { "0" });
        }

        sql.push_str(" ORDER BY created_at DESC");

        if let Some(limit) = query.limit {
            sql.push_str(&format!(" LIMIT {}", limit));
        }

        let mut query_builder = sqlx::query_as::<_, Project>(&sql);
        
        for param in bind_params {
            query_builder = query_builder.bind(param);
        }

        let projects = query_builder.fetch_all(pool).await?;
        Ok(projects)
    }

    /// Get featured projects for homepage
    pub async fn featured(pool: &SqlitePool) -> Result<Vec<Project>> {
        let projects = sqlx::query_as!(
            Project,
            "SELECT * FROM projects WHERE featured = true ORDER BY created_at DESC"
        )
        .fetch_all(pool)
        .await?;

        Ok(projects)
    }

    /// Find project by slug
    pub async fn find_by_slug(pool: &SqlitePool, slug: &str) -> Result<Option<Project>> {
        let project = sqlx::query_as!(
            Project,
            "SELECT * FROM projects WHERE slug = ?",
            slug
        )
        .fetch_optional(pool)
        .await?;

        Ok(project)
    }

    /// Get all unique categories
    pub async fn categories(pool: &SqlitePool) -> Result<Vec<String>> {
        let categories = sqlx::query_scalar!(
            "SELECT DISTINCT category FROM projects ORDER BY category"
        )
        .fetch_all(pool)
        .await?;

        Ok(categories)
    }

    /// Parse tags from JSON string
    pub fn parsed_tags(&self) -> Vec<String> {
        serde_json::from_str(&self.tags).unwrap_or_default()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::SqlitePool;

    #[sqlx::test(migrations = "./migrations")]
    async fn test_featured_projects(pool: SqlitePool) -> Result<()> {
        let projects = Project::featured(&pool).await?;
        assert!(!projects.is_empty());
        
        // All returned projects should be featured
        for project in &projects {
            assert!(project.featured);
        }

        Ok(())
    }

    #[sqlx::test(migrations = "./migrations")]
    async fn test_find_by_slug(pool: SqlitePool) -> Result<()> {
        let project = Project::find_by_slug(&pool, "nine-lives-cat-sudoku").await?;
        assert!(project.is_some());

        let project = project.unwrap();
        assert_eq!(project.slug, "nine-lives-cat-sudoku");
        assert_eq!(project.title, "Nine Lives: Cat Sudoku");

        Ok(())
    }

    #[sqlx::test(migrations = "./migrations")]
    async fn test_categories(pool: SqlitePool) -> Result<()> {
        let categories = Project::categories(&pool).await?;
        assert!(!categories.is_empty());
        assert!(categories.contains(&"Rust".to_string()));
        assert!(categories.contains(&"Web Development".to_string()));

        Ok(())
    }

    #[sqlx::test(migrations = "./migrations")]
    async fn test_all_projects_with_filter(pool: SqlitePool) -> Result<()> {
        let query = ProjectQuery {
            category: Some("Rust".to_string()),
            featured: None,
            limit: None,
        };
        
        let projects = Project::all(&pool, &query).await?;
        assert!(!projects.is_empty());

        // All returned projects should be Rust projects
        for project in &projects {
            assert_eq!(project.category, "Rust");
        }

        Ok(())
    }
}