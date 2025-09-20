use askama::Template;
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::{Html, IntoResponse},
};
use serde::Deserialize;

use crate::{
    errors::{AppError, Result},
    models::{Project, ProjectQuery},
    state::AppState,
};

#[derive(Template)]
#[template(path = "home.html")]
struct HomeTemplate {
    featured_projects: Vec<Project>,
}

#[derive(Template)]
#[template(path = "projects.html")]
struct ProjectsTemplate {
    projects: Vec<Project>,
    categories: Vec<String>,
    selected_category: String,
}

#[derive(Template)]
#[template(path = "project_detail.html")]
struct ProjectDetailTemplate {
    project: Project,
}

#[derive(Template)]
#[template(path = "project_fragment.html")]
struct ProjectFragmentTemplate {
    projects: Vec<Project>,
}

#[derive(Debug, Deserialize)]
struct ProjectsQueryParams {
    category: Option<String>,
    fragment: Option<bool>,
}

/// Homepage handler
pub async fn home_handler(State(state): State<AppState>) -> Result<impl IntoResponse> {
    let featured_projects = Project::featured(&state.pool).await?;
    
    let template = HomeTemplate { featured_projects };
    let html = template.render()?;
    
    Ok(Html(html))
}

/// Projects list handler
pub async fn projects_handler(
    State(state): State<AppState>,
    Query(params): Query<ProjectsQueryParams>,
) -> Result<impl IntoResponse> {
    // If fragment parameter is present, return partial template for htmx
    if params.fragment.unwrap_or(false) {
        let query = ProjectQuery {
            category: params.category.clone(),
            featured: None,
            limit: None,
        };
        let projects = Project::all(&state.pool, &query).await?;
        
        let template = ProjectFragmentTemplate { projects };
        let html = template.render()?;
        return Ok(Html(html));
    }
    
    // Full page response
    let query = ProjectQuery {
        category: params.category.clone(),
        featured: None,
        limit: None,
    };
    
    let projects = Project::all(&state.pool, &query).await?;
    let categories = Project::categories(&state.pool).await?;
    
    let template = ProjectsTemplate {
        projects,
        categories,
        selected_category: params.category.unwrap_or_default(),
    };
    let html = template.render()?;
    
    Ok(Html(html))
}

/// Project detail handler
pub async fn project_detail_handler(
    State(state): State<AppState>,
    Path(slug): Path<String>,
) -> Result<impl IntoResponse> {
    let project = Project::find_by_slug(&state.pool, &slug).await?;
    
    match project {
        Some(project) => {
            let template = ProjectDetailTemplate { project };
            let html = template.render()?;
            Ok(Html(html))
        }
        None => Err(AppError::NotFound(format!("Project '{}' not found", slug))),
    }
}

/// Health check endpoint
pub async fn health_handler() -> impl IntoResponse {
    (StatusCode::OK, "OK")
}

/// 404 handler
pub async fn not_found_handler() -> impl IntoResponse {
    (StatusCode::NOT_FOUND, Html(include_str!("../../templates/404.html")))
}