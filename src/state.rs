use sqlx::SqlitePool;
use crate::Config;

#[derive(Debug, Clone)]
pub struct AppState {
    pub pool: SqlitePool,
    pub config: Config,
}

impl AppState {
    pub fn new(pool: SqlitePool, config: Config) -> Self {
        Self { pool, config }
    }
}