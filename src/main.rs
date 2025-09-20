use axum::{
    routing::get,
    Router,
};
use tower::ServiceBuilder;
use tower_http::{
    services::ServeDir,
    trace::TraceLayer,
};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use personal_website::{
    config::Config,
    create_pool,
    routes::{
        home_handler, projects_handler, project_detail_handler,
        health_handler, not_found_handler,
    },
    state::AppState,
};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "personal_website=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load configuration
    let config = Config::from_env()?;
    tracing::info!("Starting personal website server on {}", config.bind_addr);

    // Create database connection pool
    let pool = create_pool(&config.database_url).await?;
    tracing::info!("Database connection established");

    // Create application state
    let state = AppState::new(pool, config.clone());

    // Build our application with routes
    let app = Router::new()
        .route("/", get(home_handler))
        .route("/projects", get(projects_handler))
        .route("/project/:slug", get(project_detail_handler))
        .route("/healthz", get(health_handler))
        .fallback(not_found_handler)
        .nest_service("/static", ServeDir::new("static"))
        .layer(
            ServiceBuilder::new()
                .layer(TraceLayer::new_for_http())
        )
        .with_state(state);

    // Create a `TcpListener` using tokio.
    let listener = tokio::net::TcpListener::bind(&config.bind_addr).await?;
    tracing::info!("Server listening on {}", config.bind_addr);
    
    // Start the server
    axum::serve(listener, app).await?;

    Ok(())
}
