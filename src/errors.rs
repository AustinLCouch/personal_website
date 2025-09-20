use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
};
use thiserror::Error;

pub type Result<T> = std::result::Result<T, AppError>;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
    
    #[error("Migration error: {0}")]
    Migration(#[from] sqlx::migrate::MigrateError),
    
    #[error("Template error: {0}")]
    Template(#[from] askama::Error),
    
    #[error("Configuration error: {0}")]
    Config(#[from] anyhow::Error),
    
    #[error("Not found: {0}")]
    NotFound(String),
    
    #[error("Validation error: {0}")]
    Validation(String),
    
    #[error("Internal server error")]
    Internal,
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, error_message): (StatusCode, String) = match self {
            AppError::Database(err) => {
                tracing::error!("Database error: {:?}", err);
                (StatusCode::INTERNAL_SERVER_ERROR, "Internal server error".to_string())
            }
            AppError::Migration(err) => {
                tracing::error!("Migration error: {:?}", err);
                (StatusCode::INTERNAL_SERVER_ERROR, "Internal server error".to_string())
            }
            AppError::Template(err) => {
                tracing::error!("Template error: {:?}", err);
                (StatusCode::INTERNAL_SERVER_ERROR, "Internal server error".to_string())
            }
            AppError::Config(err) => {
                tracing::error!("Configuration error: {:?}", err);
                (StatusCode::INTERNAL_SERVER_ERROR, "Configuration error".to_string())
            }
            AppError::NotFound(message) => {
                (StatusCode::NOT_FOUND, message)
            }
            AppError::Validation(message) => {
                (StatusCode::BAD_REQUEST, message)
            }
            AppError::Internal => {
                tracing::error!("Internal server error");
                (StatusCode::INTERNAL_SERVER_ERROR, "Internal server error".to_string())
            }
        };

        (status, error_message).into_response()
    }
}
