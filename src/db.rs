use sqlx::{SqlitePool, migrate::MigrateDatabase};
use crate::Result;

pub async fn create_pool(database_url: &str) -> Result<SqlitePool> {
    // Create database if it doesn't exist
    if !sqlx::Sqlite::database_exists(database_url).await.unwrap_or(false) {
        tracing::info!("Creating database {}", database_url);
        match sqlx::Sqlite::create_database(database_url).await {
            Ok(_) => tracing::info!("Database created successfully"),
            Err(error) => tracing::error!("Error creating database: {}", error),
        }
    }

    let pool = SqlitePool::connect(database_url).await?;
    
    // Run migrations
    tracing::info!("Running database migrations");
    sqlx::migrate!("./migrations").run(&pool).await?;
    
    Ok(pool)
}